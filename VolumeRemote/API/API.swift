import Foundation
import Combine

let URI_AUDIO = "/sec/networkaudio/audio"


enum APIMethod: String {
    case SET = "set"
}

enum APIRequestType {
    case none
    case ocfRequest
    case d2dRequest
    case httpsRequest
}



protocol APIInfoProtocol: AnyObject {
    var uri: String { get set}
    var method: APIMethod { get set}
    var headers: [String: String] { get set}
    var params: [String: Any] { get set}
    var xmlString: String { get set}
}

class APIInfo: APIInfoProtocol {
    required init(cases: requestCase, volume: Int? = nil, isMute: Bool? = nil) {
        self.uri = URI_AUDIO
        self.method = .SET
        self.xmlString = ""
        self.headers = [:]
        switch cases {
        case .setVolume:
            params = ["volume": volume ?? 5]
        case .setMute:
            params = ["mute": isMute ?? false]
        }
        
        print(
    }
    
    var uri: String
    
    var method: APIMethod
    
    var headers: [String : String]
    
    var params: [String : Any]
    
    var xmlString: String
    
    
}



protocol APINetworkProtocol: AnyObject {
    func apiRequest(speaker: SpeakerManager, apiInfo: APIInfo)
}

class APINetwork: APINetworkProtocol {
    var bags: Set<AnyCancellable> = []
    func apiRequest(speaker: SpeakerManager, apiInfo: APIInfo) {
        guard let connectionType = speaker.getSpeaker().connectionType else { return }
        if connectionType == ConnectionType.D2S {
            // D2S
            
        } else {
            let tmp = D2DManager()
            tmp.apiRequest(speaker: speaker.getSpeaker(), apiInfo: apiInfo)
                .sink { response in
                    print(response)
                    let parser = XMLParsing()
                    let data = parser.parse(xmlString: response)
                    let isMute = data?.response?.mute
                    let volume = data?.response?.volume
                    speaker.updateSpeaker(with: Speaker(volume: volume, isMute: isMute))
                    print(speaker.getSpeaker())
                }
                .store(in: &bags)
            // D2D
        }
    }
    
}
