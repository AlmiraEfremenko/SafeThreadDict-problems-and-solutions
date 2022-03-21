//: [Previous](@previous)

import UIKit
import PlaygroundSupport
import Darwin
PlaygroundPage.current.needsIndefiniteExecution = true

// Пример с deadlock на serial queue

var safeThreadQueue = DispatchQueue(label: "serialQueue")
var dict = [String: Int]()

var dictData: [String: Int] {
    
    get {
        safeThreadQueue.sync {
            dict
        }
    }
    
    set {
        safeThreadQueue.sync {
            dict = newValue
            safeThreadQueue.sync {
                dict["Cola"] = 2    // здесь будет deadlock
            }
        }
    }
}

dictData
//dictData = ["Burger": 1]
dictData

// Данный пример является решением deadlock но может привести к race condition

var safeThreadQueue1 = DispatchQueue(label: "serialQueue1")
var dict1 = [String: Int]()

var dictData1: [String: Int] {
    
    get {
        safeThreadQueue1.sync {
            dict1
        }
    }
    
    set {
        safeThreadQueue1.sync {
            dict1 = newValue
            dict1["Burger"] = 2
            print(Thread.current)  // на main потоке
            safeThreadQueue1.async {
                dict1["Cola"] = 2
                print(Thread.current)   // на каком то другом потоке
            }
        }
    }
}

dictData1                     // пустой словарь
dictData1 = ["Burger": 1]     // наш newValue
dictData1        // результат то ["Cola": 2, "Burger": 2] то ["Burger": 2, "Cola": 2] тоесть результат может быть разным

// Несмотря на данный пример поэкспериментировав пришла к выводу что все-таки race сondition чаще встречается в параллельной очереди нежели в серийной. К примеру в параллельной чаще меняются значения чем в серийной.


// Проблема с инверсией приоритетов

var safeThreadQueueUser = DispatchQueue(label: "safeThreadQueueUserinteractiv", attributes: .concurrent)

var dict2 = [String: Int]()

var dictData2: [String: Int] {
    
    get {
        safeThreadQueueUser.sync {
            dict2
        }
    }
    set {
        
        let workItem1 = DispatchWorkItem(qos: .userInitiated) { // здесь приоритет выше
            dict2 = newValue
        }
        
        let workItem2 = DispatchWorkItem(qos: .background) {
            dict2["Cola"] = 2
        }
        
        safeThreadQueueUser.async(execute: workItem1)
        safeThreadQueueUser.async(execute: workItem2)
    }
}

dictData2                     // пустой словарь
dictData2 = ["Burger": 1]     // наш newValue
dictData2                    // результат может быть  ["Cola": 2, "Burger": 1]


// Решение priority inversion

var safeThreadQueueUser1 = DispatchQueue(label: "safeThreadQueueUserinteractiv", attributes: .concurrent)

var dict3 = [String: Int]()

var dictData3: [String: Int] {
    
    get {
        safeThreadQueueUser1.sync {
            dict3
        }
    }
    set {
        
        let workItem1 = DispatchWorkItem(qos: .userInitiated, flags: .enforceQoS) { // повышаем приоритет
            dict3 = newValue
        }
        
        let workItem2 = DispatchWorkItem(qos: .background) {
            dict3["Cola"] = 2
        }
        
        safeThreadQueueUser1.async(execute: workItem1)
        safeThreadQueueUser1.async(execute: workItem2)
    }
}

dictData3                     // пустой словарь
dictData3 = ["Burger": 1]     // наш newValue
dictData3                    // мы можем задать задаче более высокий приоритет с помощью флага и эта задача будет приоритетнее

// Решение race condition

var safeThreadQueue4 = DispatchQueue(label: "concurrent", attributes: .concurrent)
var dict4 = [String: Int]()

var dictData4: [String: Int] {
    
    get {
        safeThreadQueue4.sync {
            dict4
        }
    }
    
    set {
        safeThreadQueue4.async(flags: .barrier) {
            dict4 = newValue
        }
        
        safeThreadQueue4.async {
            dict4["Cola"] = 2
        }
    }
}

dictData4                     // пустой словарь
dictData4 = ["Burger": 1]     // наш newValue
dictData4                     // Здесь результат будет то ["Burger": 1, "Cola": 2] то просто ["Burger": 1] это говорит о том что dispatch barrier в параллельной очереди задерживает задачи после него пока не выполнится блок в dispatch barrier, а также дает возможность предыдущим задачам выполниться вперед него
