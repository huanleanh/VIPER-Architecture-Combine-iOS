import Combine
import Foundation

var bags  = Set<AnyCancellable>()

//let publisher = Just(1)
//let subscriber = publisher.sink { value in
//    print(value)
//}

//let publisher = [1,2,3].publisher
//let publisher = Publishers.Sequence<[Int], Never>(sequence: [1,2,3])
//let subscriber = publisher.sink { value in
//    print(value)
//}

//let publisher = Fail<Int, Error>(error: NSError(domain: "com.example", code: 0, userInfo: nil))
//let subscriber = publisher.sink(receiveCompletion: { completion in
//    switch completion {
//    case .finished:
//        print("Publisher finished successfully")
//    case .failure(let error):
//        print("Publisher failed with error: \(error)")
//    }
//}, receiveValue: { value in
//    print("Received value: \(value)")
//})

//let publisher = Deferred {
//    Just("Hello, World!")
//}
//
//let subscriber = publisher.sink { value in
//        print(value)
//    }
//
//let pSubject = PassthroughSubject<String, Never>()
//let cSubject = CurrentValueSubject<String, Never>("Hello, World!!!")
//
//let subscription = cSubject.sink { value in
//    print("Received value: \(value)")
//}
//
//cSubject.send("Hello, World!")
//cSubject.send("Hello, World1!")
//
//subscription.cancel()

//import Combine
//
//let a = [1, 3, "c" , 4] as [Any]
//let b = ["a", "b"] as [Any]
//
//let c = a.merge(with: b)

import Combine

let numbers = (1...10).publisher

numbers
    .buffer(size: 8, prefetch: .byRequest, whenFull: .dropOldest)
    .sink { group in
        print(group)
    }


//let numbers = [1, 2, nil, 4, 5]
//let publisher = numbers.publisher
//let mappedPublisher = publisher.compactMap { value in
////    print("--", value)
//    var x: Int?
//    if let value = value { x = value*2 }
////    print("ret : ", x)
//    return x
//}
//let subscription = mappedPublisher.sink { value in
//    print(value)
//}
// Output: 2, 4, 6, 8, 10



//let publisher1 = CurrentValueSubject<Int, Never>(1)
//let publisher2 = PassthroughSubject<String, Never>()
//let combinedPublisher = publisher1.zip(publisher2)
//let subscription = combinedPublisher.sink { (value1, value2) in
//    print("Combined value: \(value1), \(value2)")
//}
////publisher1.send(1)
//
////zip(1, )
//
//publisher2.send("A")
//// zip(1,A)
////zip()
//
//publisher1.send(2)
//publisher2.send("B")
// Output:
//Combined value: 1, A
//Combined value: 2, A
//Combined value: 2, B



//enum CustomError: Error {
//    case invalidValue
//}
//let numbers = [1, 2, 3, 4, 5]
//let publisher = numbers.publisher
//    .tryMap { value -> Int in
//        guard value % 2 == 0 else {
//            throw CustomError.invalidValue
//        }
//        return value * 2
//    }
//    .sink(
//        receiveCompletion: { completion in
//            switch completion {
//            case .finished:
//                print("Finished")
//            case .failure(let error):
//                print("Error: \(error)")
//            }
//        },
//        receiveValue: { value in
//            print("Value: \(value)")
//        }
//    )
//Output: Error: invalidValue



//let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
//    .publisher
//    .multicast(subject: postsSubject)
//numbers
//    .sink(receiveValue: {
//        print("subscription1 value: \($0)") })
//    .store(in: &bags)
//DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//    numbers
//        .sink(receiveValue: { print("subscription2 value: \($0)") })
//        .store(in: &bags)
//}
//numbers
//    .connect()
//    .store(in: &bags)


//let numbers = (1...3).publisher
//let multicastSubject = PassthroughSubject<Int, Never>()
//let multicast = numbers
//    .multicast(subject: multicastSubject)
//multicast
//    .sink { value in
//        print("Subscriber 1 received value: \(value)")
//    }
//multicast
//    .sink { value in
//        print("Subscriber 2 received value: \(value)")
//    }
//
//multicast.connect()

//Subscriber 1 received value: 1
//Subscriber 2 received value: 1
//Subscriber 1 received value: 2
//Subscriber 2 received value: 2
//Subscriber 1 received value: 3
//Subscriber 2 received value: 3



//multicastSubject.send(0)
//multicastSubject.send(completion: .finished)


//let publisher1 = PassthroughSubject<Int, Never>()
//let publisher2 = PassthroughSubject<String, Never>()
//
//let zippedPublisher = publisher1.zip(publisher2)
//
//zippedPublisher.sink { value in
//    print(value)
//}
//
//publisher1.send(1)
//publisher1.send(2)
//publisher1.send(3)
//publisher1.send(3)
//publisher1.send(3)
//publisher1.send(3)
//publisher2.send("A")
//publisher2.send("s")


//let publisher1 = PassthroughSubject<Int, Never>()
//let publisher2 = PassthroughSubject<String, Never>()
//
//let combinedPublisher = publisher1.combineLatest(publisher2)
//
//combinedPublisher.sink { value in
//    print(value)
//}
//
//publisher1.send(1)
//publisher2.send("A")
//publisher1.send(2)
//publisher2.send("B")


//let publisher = [1, 2, 3, 4, 5].publisher
//
//publisher
//    .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
//    .sink { value in
//        print(value)
//    }.store(in: &bags)
//Outut: 5


//let publisher = [1, 2, 3, 4, 5].publisher
//
//publisher
//    .delay(for: .seconds(2), scheduler: DispatchQueue.main)
//    .sink { value in
//        print(value)
//    }.store(in: &bags)






//https://www.canva.com/design/DAF5ltBCM5Y/4n1b5ZP3j93nvlbZgzWDGg/edit

