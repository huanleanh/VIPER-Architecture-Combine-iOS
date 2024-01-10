////
////  Interactor.swift
////  VolumeRemote
////
////  Created by Le Anh Huan on 09/01/2024.
////
//
//import Foundation
//import Combine
//
//protocol InteractorProtocol: AnyObject {
//    var apiNetwork: APINetworkProtocol {get}
//    var speakerEntity: Speaker {get}
//    func makeAdjustVolumeRequest(volumeValue: Int)
//    func makeUpdateMuteStateRequest(isMute: Bool)
//    func updateConnection(type: ConnectionType)
//
//}
//
//class Interactor: InteractorProtocol {
//    private lazy var apiResponse = PassthroughSubject<(isMute: Bool?, volume: Int?), Never>()
//
//    var bags: Set<AnyCancellable> = []
//
//    internal var apiNetwork: APINetworkProtocol
//
//    var speakerEntity: Speaker {return SpeakerManager.shared.getSpeaker()}
//
//    init(apiNetwork: APINetworkProtocol) {
//        self.apiNetwork = apiNetwork
//
//        apiResponse.sink { (isMute, volume) in
//            if let volume = volume {
//                SpeakerManager.shared.updateSpeaker(with: Speaker(volume: volume))
//            } else {
//                SpeakerManager.shared.updateSpeaker(with: Speaker(isMute: isMute))
//            }
//        }.store(in: &bags)
//    }
//
//    func makeAdjustVolumeRequest(volumeValue: Int) {
//        print("I: adjust volume")
//        let speaker = SpeakerManager.shared
//        APINetwork().apiRequest(speaker: speaker, apiInfo: APIInfo.init(cases: .setVolume, volume: volumeValue))
//        SpeakerManager.shared.updateSpeaker(with: Speaker(volume: volumeValue))
//    }
//
//    func makeUpdateMuteStateRequest(isMute: Bool) {
//        let speaker = SpeakerManager.shared
//        APINetwork().apiRequest(speaker: speaker, apiInfo: APIInfo.init(cases: .setMute, isMute: isMute) )
//        SpeakerManager.shared.updateSpeaker(with: Speaker(isMute: isMute))
//    }
//
//    func updateConnection(type: ConnectionType) {
//        SpeakerManager.shared.updateSpeaker(with: Speaker(connectionType: type))
//    }
//
//    weak var presenter: PresenterProtocol?
//
//}



import Foundation
import Combine

protocol InteractorProtocol: AnyObject {
    func makeAdjustVolumeRequest(volumeValue: Int)
    func makeUpdateMuteStateRequest(isMute: Bool)
    func updateConnection(type: ConnectionType)
}

class Interactor: InteractorProtocol {
    private let useCase: UseCaseProtocol
    
    init(speakerRepository: SpeakerRepositoryProtocol, initialSpeaker: Speaker) {
        self.useCase = UseCase(speakerRepository: speakerRepository, initialSpeaker: initialSpeaker)
    }
    func makeAdjustVolumeRequest(volumeValue: Int) {
        useCase.adjustVolume(volumeValue: volumeValue)
    }
    
    func makeUpdateMuteStateRequest(isMute: Bool) {
        useCase.updateMuteState(isMute: isMute)
    }
    
    func updateConnection(type: ConnectionType) {
        useCase.updateConnection(type: type)
    }
}

protocol UseCaseProtocol: AnyObject {
    var speakerRepository: SpeakerRepositoryProtocol { get }
    var speaker: Speaker { get set } // Thêm thuộc tính speaker
    
    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
}

class UseCase: UseCaseProtocol {
    internal let speakerRepository: SpeakerRepositoryProtocol
    var speaker: Speaker // Khởi tạo speaker
    
    init(speakerRepository: SpeakerRepositoryProtocol, initialSpeaker: Speaker) { // Thêm tham số initialSpeaker
        self.speakerRepository = speakerRepository
        self.speaker = initialSpeaker // Gán giá trị ban đầu cho speaker
    }
    
    func adjustVolume(volumeValue: Int) {
        speakerRepository.request(speaker: speaker, apiInfo: APIInfo(cases: .setVolume, volume: volumeValue))
    }
    
    func updateMuteState(isMute: Bool) {
        speakerRepository.request(speaker: speaker, apiInfo: APIInfo(cases: .setMute, isMute: isMute))
    }
    
    func updateConnection(type: ConnectionType) {
        speakerRepository.updateConnection(type: type) // Không cần gọi API cho trường hợp này
    }
    
}

