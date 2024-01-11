//
//  Interactor.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation
import Combine

protocol InteractorProtocol: AnyObject {
    var interactorPublisher: PassthroughSubject<VolumeEvent, Never> { get }
    
    func makeAdjustVolumeRequest(volumeValue: Int)
    func makeUpdateMuteStateRequest(isMute: Bool)
    func updateConnection(type: ConnectionType)
    func getUseCase() -> UseCaseProtocol
}

class Interactor: InteractorProtocol {
    private let useCase: UseCaseProtocol
    
    private(set) var interactorPublisher = PassthroughSubject<VolumeEvent, Never>()
    private var bags = Set<AnyCancellable>()
    
    init(speakerRepository: SpeakerRepositoryProtocol, speaker: Speaker) {
        self.useCase = UseCase(speakerRepository: speakerRepository, speaker: speaker)
        
        speakerRepository.repoPublisher.sink { [weak self] event in
            self?.interactorPublisher.send(event)
        }
        .store(in: &bags)
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
    
    func getUseCase() -> UseCaseProtocol{
        return self.useCase
    }
}

protocol UseCaseProtocol: AnyObject {
    var speakerRepository: SpeakerRepositoryProtocol { get }
    
    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
    func getSpeaker() -> Speaker
}

class UseCase: UseCaseProtocol {
    internal let speakerRepository: SpeakerRepositoryProtocol
    
    init(speakerRepository: SpeakerRepositoryProtocol, speaker: Speaker) {
        self.speakerRepository = speakerRepository
    }
    
    func adjustVolume(volumeValue: Int) {
        print("Going to make a request to change Speaker's volume to \(volumeValue)")
        speakerRepository.request(speaker: speakerRepository.getSpeaker(), apiInfo: APIInfo(cases: .setVolume(volume: volumeValue)))
    }
    
    func updateMuteState(isMute: Bool) {
        print("Going to make a request to change Speaker's mute state to \(isMute)")

        speakerRepository.request(speaker: speakerRepository.getSpeaker(), apiInfo: APIInfo(cases: .setMute(isMute: isMute)))
    }
    
    func updateConnection(type: ConnectionType) {
        speakerRepository.updateConnection(type: type)
    }
    
    func getSpeaker() -> Speaker {
//        print("get dc thong tin tu usecase: \(self.speakerRepository.getSpeaker().volume)")
        return self.speakerRepository.getSpeaker()
    }
    
}

