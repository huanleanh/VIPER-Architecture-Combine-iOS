

import Foundation
import Combine

protocol D2dManagerProtocol {
    func apiRequest(speaker: Speaker, apiInfo: APIInfoProtocol) -> AnyPublisher<String, Never>
}

class D2DManager: D2dManagerProtocol {
    func apiRequest(speaker: Speaker, apiInfo: APIInfoProtocol)  -> AnyPublisher<String, Never> {
        return Future<String, Never> { promise in
            print(2)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let responseString = self.getSetVolumeResponse(speaker: speaker, apiInfo: apiInfo)
                print(4)
                promise(.success(responseString))
            }
        }.eraseToAnyPublisher()
    }
    
    func buildSetVolumeRequest(speaker: Speaker, apiInfo: APIInfoProtocol) {
        
    }
    
    func getSetVolumeResponse(speaker: Speaker, apiInfo:APIInfoProtocol) -> String {
        let ret = String("<?xml version=\"1.0\" encoding=\"UTF-8\"?><UIC><method>VolumeLevel</method><version>1.0</version><speakerip>192.168.106.202</speakerip><user_identifier>28268B6C-3C47-4DBE-88F9-97AEF8BECCD7</user_identifier><response result=\"ok\"><volume></volume></response></UIC>".replacingOccurrences(of: "<volume></volume>", with: "<volume>\(Int.random(in: 1...10))</volume>"))
        return ret
    }
    
    func buildSetMuteRequest(speaker: Speaker, apiInfo:APIInfoProtocol) {
        
    }
    
    func getSetMuteResponse(speaker: Speaker, apiInfo:APIInfoProtocol) {
        
    }
}

