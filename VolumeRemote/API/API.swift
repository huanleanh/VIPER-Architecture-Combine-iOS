//import Foundation
//import Combine
//
//let URI_AUDIO = "/sec/networkaudio/audio"
//
//
//enum APIMethod: String {
//    case SET = "set"
//}
//
//enum APIRequestType {
//    case none
//    case ocfRequest
//    case d2dRequest
//    case httpsRequest
//}
//
//
//
//protocol APIInfoProtocol: AnyObject {
//    var uri: String { get set}
//    var method: APIMethod { get set}
//    var headers: [String: String] { get set}
//    var params: [String: Any] { get set}
//    var xmlString: String { get set}
//}
//
//class APIInfo: APIInfoProtocol {
//    required init(cases: requestCase, volume: Int? = nil, isMute: Bool? = nil) {
//        self.uri = URI_AUDIO
//        self.method = .SET
//        self.xmlString = ""
//        self.headers = [:]
//        switch cases {
//        case .setVolume:
//            params = ["volume": volume ?? 5]
//        case .setMute:
//            params = ["mute": isMute ?? false]
//        }
//
//        print(self)
//    }
//
//    var uri: String
//
//    var method: APIMethod
//
//    var headers: [String : String]
//
//    var params: [String : Any]
//
//    var xmlString: String
//
//
//}
//
//
//
//protocol APINetworkProtocol: AnyObject {
//    func apiRequest(speaker: SpeakerManager, apiInfo: APIInfo)
//
//}
//
//class APINetwork: APINetworkProtocol {
//    var bags: Set<AnyCancellable> = []
//    func apiRequest(speaker: SpeakerManager, apiInfo: APIInfo) {
//
//        guard let connectionType = speaker.getSpeaker().connectionType else { return }
//        if connectionType == ConnectionType.D2S {
//            // D2S
//
//        } else {
//            // D2D
//            let tmp = D2DManager()
//            print(1)
//            tmp.apiRequest(speaker: speaker.getSpeaker(), apiInfo: apiInfo)
//                .subscribe(on: RunLoop.main)
//                .sink(receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("API request completed successfully")
//                    case .failure(let error):
//                        print("API request failed with error: \(error)")
//                    }
//                }, receiveValue: { responseString in
//                    print(3)
//                    print(responseString)
//                    DispatchQueue.main.async {
//                        let parser = XMLParsing()
//                        let data = parser.parse(xmlString: responseString)
//                        let isMute = data?.response?.mute
//                        var volume = data?.response?.volume
//                        apiResponse.send(isMute, volume)
//                        print(speaker.getSpeaker())
//                    }
//                })
//                .store(in: &bags) // Lưu trữ subscription để hủy nếu cần
//        }
//    }
//}
//



import Foundation
import Combine

struct APIInfo {
    var uri: String
        var method: APIMethod
        var headers: [String: String]
        var params: [String: Any]

        enum APIMethod: String {
            case SET = "set"
            case GET = "get"
        }

        enum Cases {
            case setVolume(volume: Int)
            case setMute(isMute: Bool)
        }

        init(cases: Cases) {
            switch cases {
            case .setVolume(let volume):
                uri = "/api/speakers/volume"
                method = .SET
                params = ["volume": volume]
            case .setMute(let isMute):
                uri = "/api/speakers/mute"
                method = .SET
                params = ["isMute": isMute]
            }
        }
}

enum APIMethod: String {
    case SET = "set"
}

protocol APINetworkProtocol: AnyObject {
    func request(speaker: Speaker, apiInfo: APIInfo) -> AnyPublisher<(isMute: Bool?, volume: Int?), Never>
}

class APINetwork: APINetworkProtocol {
    private let apiClient: APIClientProtocol
    var bags: Set<AnyCancellable> = []

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func request(speaker: Speaker, apiInfo: APIInfo) -> AnyPublisher<(isMute: Bool?, volume: Int?), Never> {
//        let url = URL(string: apiInfo.uri)!
//        let request = URLRequest(url: url)
//        request.httpMethod = apiInfo.method.rawValue
//        request.setValue(apiInfo.headers.description, forHTTPHeaderField: "Authorization")
//        request.httpBody = apiInfo.params.encode()
//
//        return apiClient.request(request)
//            .map { response in
//                guard let data = response.data else { return (nil, nil) }
//                let decoder = JSONDecoder()
//                let result = try decoder.decode(APIResponse.self, from: data)
//                return (result.isMute, result.volume)
//            }
//            .eraseToAnyPublisher()
        guard let connectionType = speaker.getSpeaker().connectionType else { return }
               if connectionType == ConnectionType.D2S {
                   // D2S
       
               } else {
                   // D2D
                   let tmp = D2DManager()
                   print(1)
                   tmp.apiRequest(speaker: speaker.getSpeaker(), apiInfo: apiInfo)
                       .subscribe(on: RunLoop.main)
                       .sink(receiveCompletion: { completion in
                           switch completion {
                           case .finished:
                               print("API request completed successfully")
                           case .failure(let error):
                               print("API request failed with error: \(error)")
                           }
                       }, receiveValue: { responseString in
                           print(3)
                           print(responseString)
                           DispatchQueue.main.async {
                               let parser = XMLParsing()
                               let data = parser.parse(xmlString: responseString)
                               let isMute = data?.response?.mute
                               var volume = data?.response?.volume
//                               apiResponse.send(isMute, volume)
                               print(speaker.getSpeaker())
                           }
                       })
                       .store(in: &bags) // Lưu trữ subscription để hủy nếu cần
               }
    }
}

protocol APIClientProtocol: AnyObject {
    func request(_ request: URLRequest) -> AnyPublisher<Data, Error>
}

class APIClient: APIClientProtocol {
    private let session: URLSession

    init(session: URLSession = URLSession.shared) {
        self.session = session
    }

    func request(_ request: URLRequest) -> AnyPublisher<Data, Error> {
        return session.dataTaskPublisher(for: request)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

struct APIResponse: Decodable {
    var isMute: Bool?
    var volume: Int?
}
