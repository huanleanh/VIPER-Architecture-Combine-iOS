//
//  Repository.swift
//  VolumeRemote
//
//  Created by Huan Le A. on 11/01/2024.
//

import Foundation
import Combine

protocol SpeakerRepositoryProtocol: AnyObject {
    var repoPublisher: PassthroughSubject<VolumeEvent, Never> { get }
    func getSpeaker() -> Speaker
    func updateSpeaker(with speaker: Speaker)
    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
    func request(speaker: Speaker, apiInfo: APIInfo)
}

class SpeakerRepository: SpeakerRepositoryProtocol {
    private let speakerStore: SpeakerStore
    private let APINetwork: APINetworkProtocol
    
    private(set) var repoPublisher = PassthroughSubject<VolumeEvent, Never>()
    private var bags: Set<AnyCancellable> = []

    init(speakerStore: SpeakerStore) {
        self.speakerStore = speakerStore
        self.APINetwork = VolumeRemote.APINetwork()
    }

    func getSpeaker() -> Speaker {
        return speakerStore.getSpeaker()
    }

    func updateSpeaker(with speaker: Speaker) {
        speakerStore.updateSpeaker(with: speaker)
    }

    func adjustVolume(volumeValue: Int) {
        speakerStore.adjustVolume(volumeValue: volumeValue)
    }

    func updateMuteState(isMute: Bool) {
        speakerStore.updateMuteState(isMute: isMute)
    }

    func updateConnection(type: ConnectionType) {
        speakerStore.updateConnection(type: type)
    }
    
    func request(speaker: Speaker, apiInfo: APIInfo) {
        APINetwork.request(speakerRepo: self, apiInfo: apiInfo)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                print("API request completed successfully")
            case .failure(let error):
                print("API request failed with error: \(error)")
            }
        }, receiveValue: { [weak self] (isMute, volume) in
            if let isMute = isMute {
                self?.updateSpeaker(with: Speaker(isMute: isMute))
                self?.repoPublisher.send(.muteStateHasUpdated)
            }
            if let volume = volume {
                self?.updateSpeaker(with: Speaker(volume: volume))
                self?.repoPublisher.send(.volumeHasUpdated)
            }
        })
        .store(in: &bags)
        }
}

class SpeakerStore {
    private var speaker: Speaker

    init(speaker: Speaker) {
        self.speaker = speaker
    }

    func getSpeaker() -> Speaker {
        return speaker
    }

    func updateSpeaker(with speaker: Speaker) {
        if speaker.isMute != nil {
//            print("Updated mute state")
            self.speaker.isMute = speaker.isMute
        }
        if speaker.volume != nil {
//            print( "Updated volume")
            self.speaker.volume = speaker.volume
        }
    }

    func adjustVolume(volumeValue: Int) {
        speaker.volume = volumeValue
    }

    func updateMuteState(isMute: Bool) {
        speaker.isMute = isMute
    }

    func updateConnection(type: ConnectionType) {
        print ("update connection type: ", type)
        speaker.connectionType = type
//        print("New speaker value: ", speaker)
    }
}
