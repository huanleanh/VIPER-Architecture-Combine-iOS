import Combine
import Foundation

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

//let pSubject = PassthroughSubject<String, Never>()
//let cSubject = CurrentValueSubject<String, Never>("Hello, World!!!")
//
//// Subscribe to the PassthroughSubject
//let subscription = pSubject.sink { value in
//    print("Received value: \(value)")
//}
//
//// Send a value through the PassthroughSubject
//pSubject.send("Hello, World!")
//
//// Cancel the subscription
//subscription.cancel()

//let numbers = [1, 2, 3, 4, 5]
//let sum = numbers.publisher
//    .reduce(0, { accumulator, value in
//        return accumulator - value
//    })
//
//sum.sink { value in
//    print("Sum: \(value)")
//}


//let numbers = [1, 2, 3, 4, 5]
//let publisher = numbers.publisher
//let mappedPublisher = publisher.map { $0 * 2 }
//let subscription = mappedPublisher.sink { value in
//    print(value)
//}
// Output: 2, 4, 6, 8, 10


//let publisher1 = PassthroughSubject<Int, Never>()
//let publisher2 = PassthroughSubject<String, Never>()
//let combinedPublisher = publisher1.combineLatest(publisher2)
//let subscription = combinedPublisher.sink { (value1, value2) in
//    print("Combined value: \(value1), \(value2)")
//}
//publisher1.send(1)
//publisher2.send("A")
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

var bags  = Set<AnyCancellable>()
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


let numbers = (1...3).publisher
let multicastSubject = PassthroughSubject<Int, Never>()
let multicast = numbers
    .multicast(subject: multicastSubject)
multicast
    .sink { value in
        print("Subscriber 1 received value: \(value)")
    }
multicast
    .sink { value in
        print("Subscriber 2 received value: \(value)")
    }

multicast.connect()

//Subscriber 1 received value: 1
//Subscriber 2 received value: 1
//Subscriber 1 received value: 2
//Subscriber 2 received value: 2
//Subscriber 1 received value: 3
//Subscriber 2 received value: 3



//multicastSubject.send(0)
multicastSubject.send(completion: .finished)



