
import Foundation
import SCClient

enum OCFResponseType {
    case subscribe
    case set
}

protocol IOCFResponse {
    var speaker: ISpeaker { get set }
    var apiInfo: IAPIInfo? { get set }
    var uri: String? { get set }
    var attr: OBJC_RCSResourceAttributes? { get set }
    var result: OBJC_eOCFResult { get set }
    var responseType: OCFResponseType { get set }
}

struct OCFResponse: IOCFResponse {
    var speaker: ISpeaker
    var apiInfo: IAPIInfo?
    var uri: String?
    var attr: OBJC_RCSResourceAttributes?
    var result: OBJC_eOCFResult
    var responseType: OCFResponseType
    
    init(speaker: ISpeaker,
         apiInfo: IAPIInfo? = nil,
         uri: String? = nil,
         attr: OBJC_RCSResourceAttributes? = nil,
         result: OBJC_eOCFResult,
         responseType: OCFResponseType = .subscribe) {
        self.speaker = speaker
        self.apiInfo = apiInfo
        self.uri = uri
        self.attr = attr
        self.result = result
        self.responseType = responseType
    }
}
