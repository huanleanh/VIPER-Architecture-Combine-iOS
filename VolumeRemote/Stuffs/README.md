

import Foundation
import Combine
@testable import SPKController

final class MockOCFManager: IOCFManager {
    lazy var ocfResources: [String: IOCFProcess] = OCFManager.ocfResources()
    var fakeSb: IFakeSoundbar
    
    init(fakeSb: IFakeSoundbar) {
        self.fakeSb = fakeSb
    }
    
    func initializer() {
        
    }
    
    func released() {
        
    }
    
    func startMonitoring(speaker: ISpeaker) -> Bool {
        return false
    }
    
    func stopMonitoring(speaker: ISpeaker) {
        
    }
    
    func observerDeviceEvent(deviceId: String) {
        
    }
    
    func stopObservingDeviceEvent() {
        
    }
    
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>? {
        switch apiInfo.method {
        case .GET:
            return get(speaker: speaker, apiInfo: apiInfo)
        case .SET:
            return set(speaker: speaker, apiInfo: apiInfo)
        default:
            return nil
        }
    }
    
    func get(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {
        let fakeSbResponse = fakeSb.getRemoteAttribute(uri: apiInfo.uri)
        let response = OCFResponse(speaker: speaker, apiInfo: apiInfo, uri: apiInfo.uri, attr: fakeSbResponse.attr, result: fakeSbResponse.result)
        if let ocfProcess = ocfResources[apiInfo.uri] {
            ocfProcess.handle(response: response)
        }
        return Just(response)
            .setFailureType(to: OCFError.self)
            .eraseToAnyPublisher()
    }
    
    func set(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {
        let attr = OCFHelper.convertToAttributes(params: apiInfo.params)
        let fakeSbResponse = fakeSb.setRemoteAttribute(uri: apiInfo.uri, attr: attr)
        let response = OCFResponse(speaker: speaker, apiInfo: apiInfo, uri: apiInfo.uri, attr: fakeSbResponse.attr, result: fakeSbResponse.result)
        if let ocfProcess = ocfResources[apiInfo.uri] {
            ocfProcess.handle(response: response)
        }
        return Just(response)
            .setFailureType(to: OCFError.self)
            .eraseToAnyPublisher()
    }
    
    func makeResources(speaker: VLSpeaker) -> [String: VLOcfResource] {
        return [:]
    }
}

