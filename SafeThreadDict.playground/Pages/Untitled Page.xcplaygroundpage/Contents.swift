//: [Previous](@previous)

import UIKit
import PlaygroundSupport
PlaygroundPage.current.needsIndefiniteExecution = true

// Dispatch Group простой пример

var queue = DispatchQueue(label: "", attributes: .concurrent)

var array = [Int]()

queue.async {
    array.append(1)
    print("Add 1")
}

queue.async {
    array.append(2)
    print("Add 2")
}

queue.async {
    array.append(3)
    print("Add 3")
}
queue.async {
    array.append(contentsOf: [4, 5, 6])
    print("Add 4, 5, 6")
    
}
queue.async {
    print("End add elements")
}

array   // результат разный может быть

print("------------------------------")

// Решение с помощью Dispatch group
var queue1 = DispatchQueue(label: "", attributes: .concurrent)
var group1 = DispatchGroup()

var array1 = [Int]()

group1.enter()
queue1.async {
    array1.append(1)
    print("Add 1")
    group1.leave()
}

group1.enter()
queue1.async {
    array1.append(2)
    print("Add 2")
    group1.leave()
}

group1.enter()
queue1.async {
    array1.append(3)
    print("Add 3")
    group1.leave()
}

group1.enter()
queue1.async {
    array1.append(contentsOf: [4, 5, 6])
    print("Add 4, 5, 6")
    group1.leave()
}

group1.enter()
queue1.async {
    print("End add elements")
    group1.leave()
}

group1.notify(queue: .main) {
    print("Tasks completed ")
}

array1     // результат последовательный

// Пример с запросом картинок

class EightImage: UIView {
    
    public var ivs = [UIImageView]()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        ivs.append(UIImageView(frame: CGRect(x: 100, y: 100, width: 100, height: 100)))
        ivs.append(UIImageView(frame: CGRect(x: 200, y: 100, width: 100, height: 100)))
        ivs.append(UIImageView(frame: CGRect(x: 200, y: 200, width: 100, height: 100)))
        ivs.append(UIImageView(frame: CGRect(x: 100, y: 200, width: 100, height: 100)))
        
        for i in ivs.indices {
            ivs[i].contentMode = .scaleAspectFit
            self.addSubview(ivs[i])
        }
}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

var view = EightImage(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
view.backgroundColor = .yellow

var url = ["https://klike.net/uploads/posts/2019-06/1560329641_2.jpg", "https://bipbap.ru/wp-content/uploads/2017/04/priroda_kartinki_foto_03.jpg", "https://www.imgonline.com.ua/examples/bee-on-daisy.jpg", "https://bipbap.ru/wp-content/uploads/2017/08/04.-risunki-dlya-srisovki-legkie-dlya-devochek.jpg"]


var images = [UIImage]()

PlaygroundPage.current.liveView = view

func asyncLoadImage(imageUrl: URL,
                    runQueu: DispatchQueue,
                    completionQueue: DispatchQueue,
                    completion: @escaping (UIImage?, Error?) -> ()) {
    
    runQueu.async {
        do {
            let data = try Data(contentsOf: imageUrl)
            completionQueue.async { completion(UIImage(data: data), nil)}
        } catch let error {
            completionQueue.async { completion(nil, error) }
        }
    }
}

func asyncGroup() {
    let aGroup = DispatchGroup()
    
    for i in 0...3 {
        aGroup.enter()
        asyncLoadImage(imageUrl: URL(string: url[i])!, runQueu: .global(),
                       completionQueue: .main) { (result, error) in
            guard let image1 = result else { return }
            images.append(image1)
            aGroup.leave()
        }
    }
    
    aGroup.notify(queue: .main) {
        for i in 0...3 {
            view.ivs[i].image = images[i]
        }
    }
}

asyncGroup()
