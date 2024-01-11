

import Foundation
import Combine

protocol D2dManagerProtocol {
    func apiRequest(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo) -> AnyPublisher<String, Never>
}

class D2DManager: D2dManagerProtocol {
    func apiRequest(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo)  -> AnyPublisher<String, Never> {
        
        switch apiInfo.useCase {
        case .setVolume:
            print("\n>>>>>\nSend XML request:\n", buildSetVolumeRequest(speaker: speakerRepo.getSpeaker(), apiInfo: apiInfo))
        case .setMute:
            print("\n>>>>>\nSend XML request:\n", buildSetMuteRequest(speaker: speakerRepo.getSpeaker(), apiInfo: apiInfo))
        }
        
        return Future<String, Never> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                switch apiInfo.useCase {
                case .setVolume:
                    let responseString = self.getSetVolumeResponse(speaker: speakerRepo.getSpeaker(), apiInfo: apiInfo)
                    promise(.success(responseString))
                case .setMute:
                    let responseString = self.getSetMuteResponse(speaker: speakerRepo.getSpeaker(), apiInfo: apiInfo)
                    promise(.success(responseString))
                }
                
            }
        }.eraseToAnyPublisher()
    }
    
    func buildSetVolumeRequest(speaker: Speaker, apiInfo: APIInfo) -> String {
        let volumeStringValue = String((apiInfo.params[0].volume)!)
        return "<pwron>on</pwron><name>SetVolume</name><p type=\"dec\" name=\"volume\" val=\"\(volumeStringValue)\"/>"
    }
    
    func getSetVolumeResponse(speaker: Speaker, apiInfo:APIInfo) -> String {
        let ret = String("<?xml version=\"1.0\" encoding=\"UTF-8\"?><UIC><method>VolumeLevel</method><version>1.0</version><speakerip>192.168.106.202</speakerip><user_identifier>28268B6C-3C47-4DBE-88F9-97AEF8BECCD7</user_identifier><response result=\"ok\"><volume></volume></response></UIC>".replacingOccurrences(of: "<volume></volume>", with: "<volume>\(Int.random(in: 1...10))</volume>"))
        return ret
    }
    
    func buildSetMuteRequest(speaker: Speaker, apiInfo:APIInfo) -> String {
        let isMuteStringValue = String((apiInfo.params[0].isMute)! ? "on" : "off")
        return "<pwron>on</pwron><name>SetMute</name><p type=\"str\" name=\"mute\" val=\"\(isMuteStringValue)\"/>"
    }
    
    func getSetMuteResponse(speaker: Speaker, apiInfo:APIInfo)  -> String {
        let replaceText = (apiInfo.params[0].isMute ?? false) ? "on" : "off"
        return "<?xml version=\"1.0\" encoding=\"UTF-8\"?><UIC><method>MuteStatus</method><version>1.0</version><speakerip>192.168.106.202</speakerip><user_identifier>28268B6C-3C47-4DBE-88F9-97AEF8BECCD7</user_identifier><response result=\"ok\"><mute></mute></response></UIC>".replacingOccurrences(of: "<mute></mute>", with: "<mute>\(replaceText)</mute>")
    }
}

