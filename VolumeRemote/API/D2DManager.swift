

import Foundation
import Combine

protocol D2dManagerProtocol {
    func apiRequest(speaker: Speaker, apiInfo: APIInfoProtocol) -> AnyPublisher<String, Never>
}

class D2DManager: D2dManagerProtocol {
    func apiRequest(speaker: Speaker, apiInfo: APIInfoProtocol)  -> AnyPublisher<String, Never> {
        return Future<String, Never> { promise in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    let responseString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><UIC><method>VolumeLevel</method><version>1.0</version><speakerip>192.168.106.202</speakerip><user_identifier>28268B6C-3C47-4DBE-88F9-97AEF8BECCD7</user_identifier><response result=\"ok\"><volume>28</volume></response></UIC>"

                    promise(.success(responseString))
                }
            }.eraseToAnyPublisher()
    }
}
