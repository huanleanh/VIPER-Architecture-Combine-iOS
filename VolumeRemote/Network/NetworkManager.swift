import Foundation
import Combine

let URI_AUDIO = "/sec/networkaudio/audio"

enum requestCase {
    case setVolume
    case setMute
}

struct APIInfo {
    var uri: String
    var method: APIMethod
    var headers: [String: String] = [:]
    var params: [Atrribute]
    var useCase: requestCase
    
    enum APIMethod: String {
        case SET = "set"
        case GET = "get"
    }
    
    enum CodingKeys: String {
        case uri
        case method
        case headers
        case params
        case useCase
    }
    
    enum Cases {
        case setVolume(volume: Int)
        case setMute(isMute: Bool)
    }
    
    init(cases: Cases, volume: Int? = nil, isMute: Bool? = nil) {
        switch cases {
        case .setVolume(let volume):
            uri = URI_AUDIO
            method = .SET
            params = [Atrribute(volume: volume, isMute: nil)]
            useCase = .setVolume
        case .setMute(let isMute):
            uri = URI_AUDIO
            method = .SET
            params = [Atrribute(volume: nil, isMute: isMute)]
            useCase = .setMute
        }
    }
}

struct Atrribute: Encodable, Decodable {
    let volume: Int?
    let isMute: Bool?
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(volume, forKey: .volume)
        try container.encode(isMute, forKey: .isMute)
    }
    init(volume: Int?, isMute: Bool?) {
        self.volume = volume ?? nil
        self.isMute = isMute ?? nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        volume = try container.decode(Int.self, forKey: .volume)
        isMute = try container.decode(Bool.self, forKey: .isMute)
    }
    
    enum CodingKeys: String, CodingKey {
        case volume = "volume"
        case isMute = "mute"
    }
}


enum APIMethod: String {
    case SET = "set"
}

protocol APINetworkProtocol: AnyObject {
    func request(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo) -> AnyPublisher<(isMute: Bool?, volume: Int?), Never>
}

class APINetwork: APINetworkProtocol {
    private let d2dManager: D2dManagerProtocol
    private let d2sManager: D2SManagerProtocol
    var bags: Set<AnyCancellable> = []
    
    init() {
        self.d2dManager = D2DManager()
        self.d2sManager = D2SManager()
    }
    
    func request(speakerRepo: SpeakerRepositoryProtocol, apiInfo: APIInfo) -> AnyPublisher<(isMute: Bool?, volume: Int?), Never> {
        guard let connectionType = speakerRepo.getSpeaker().connectionType else {
            return Just((isMute: nil, volume: nil)).eraseToAnyPublisher()
        }
        if connectionType == ConnectionType.D2S {
            // D2S
            return d2sManager.apiRequest(speakerRepo: speakerRepo, apiInfo: apiInfo)
                .flatMap { responseString -> AnyPublisher<(isMute: Bool?, volume: Int?), Never> in
                    print("\n<<<<<<<\nReceived response:\n \(responseString)\n")
                    let decoder = JSONDecoder()
                    guard let jsonData = responseString.data(using: .utf8) else {
                        return Just((isMute: nil, volume: nil)).eraseToAnyPublisher()
                    }
                    var info  = Atrribute.init(volume: nil, isMute: nil)
                    do {
                        info = try decoder.decode(Atrribute.self, from: jsonData)
                    } catch {
                        print("Lỗi giải mã JSON:", error)
                    }
//                    print( "got value", info)
                    return Just((isMute: info.isMute, volume: info.volume)).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        } else {
            // D2D
            return d2dManager.apiRequest(speakerRepo: speakerRepo, apiInfo: apiInfo)
                .flatMap { responseString -> AnyPublisher<(isMute: Bool?, volume: Int?), Never> in
                    print("\n<<<<<<<\nReceived response:\n \(responseString)\n")
                    let parser = XMLParsing()
                    let data = parser.parse(xmlString: responseString)
                    let isMute = data?.response?.mute ?? nil
                    let volume = data?.response?.volume ?? nil
                    return Just((isMute: isMute, volume: volume)).eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
        }
    }
}

struct APIResponse: Decodable {
    var isMute: Bool?
    var volume: Int?
}
