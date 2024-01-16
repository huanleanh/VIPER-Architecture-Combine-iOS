

import Foundation
import Combine

protocol D2SManagerProtocol {
    func apiRequest(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo) -> AnyPublisher<String, Never>
}

final class D2SManager: D2SManagerProtocol {
    func apiRequest(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo) -> AnyPublisher<String, Never> {
        let encoder = JSONEncoder()
        do {
            let attr = try encoder.encode(apiInfo.params[0])
            switch apiInfo.useCase {
            case .setVolume:
                print("\n>>>>>\nSend JSON request\n URI:", apiInfo.uri, "\nAttr:", String(data: attr, encoding: .utf8)!)
            case .setMute:
                print("\n>>>>>\nSend JSON request\n URI:", apiInfo.uri, "\nAttr:", String(data: attr, encoding: .utf8)!)
            }
        }
        catch {
            print("Error when encode")
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
    
    func getSetVolumeResponse(speaker: Speaker, apiInfo:APIInfo) -> String {
        return "{\n\t\"volume\":\t\(apiInfo.params[0].volume!),\n\t\"mute\":\tfalse\n}"
    }
    
    func getSetMuteResponse(speaker: Speaker, apiInfo:APIInfo)  -> String {
        return "{\n\t\"volume\":\t\(Int(speaker.volume ?? 5)),\n\t\"mute\":\t\(Bool(apiInfo.params[0].isMute ?? false))\n}"
    }
    
}
