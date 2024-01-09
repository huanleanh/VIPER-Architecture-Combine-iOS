import Foundation

enum APIMethod: String {
    case NONE = "none"
    case GET = "get"
    case SET = "set"
    case POST = "post"
    case DELETE = "delete"
}

enum APIRequestType {
    case none
    case ocfRequest
    case d2dRequest
    case httpsRequest
}

enum HTTPSAPIVersion: String {
    case v1 = "v1"
    case v2 = "v2"
    case v3 = "v3"
}

enum HTTPSResponseState {
    case response
    case error
}

protocol ID2DInfo {
    var xmlString: String { get }
}

protocol IAPIInfo: ID2DInfo {
    var uri: String { get }
    var method: APIMethod { get }
    var headers: [String: String] { get }
    var params: [String: Any] { get }
    
    func apiRequestType(connectionType: ConnectionType) -> APIRequestType
}

extension IAPIInfo {
    var headers: [String: String] {
        return [:]
    }
    
    var xmlString: String {
        return "write xml string for D2D"
    }
    
    var urlRequest: URLRequest? {
        MALOG("Please implement")
        return nil
    }

}

protocol IHTTPSAPIInfo: IAPIInfo {
    var version: HTTPSAPIVersion { get }
    var urlRequest: URLRequest? { get }
    
    var process: IHTTPSProcess { get }
    
    func responseState(code: String?) -> HTTPSResponseState
}

extension IHTTPSAPIInfo {
    func responseState(code: String?) -> HTTPSResponseState {
        return .response
    }
}
