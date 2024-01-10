//
//  Repository.swift
//  VolumeRemote
//
//  Created by Huan Le A. on 11/01/2024.
//

import Foundation

protocol SpeakerRepositoryProtocol: AnyObject {
    func getSpeaker() -> Speaker
    func updateSpeaker(with speaker: Speaker)
    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
    func request(speaker: Speaker, apiInfo: APIInfo)
}

class SpeakerRepository: SpeakerRepositoryProtocol {
    private let speakerStore: SpeakerStore

    init(speakerStore: SpeakerStore) {
        self.speakerStore = speakerStore
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
            // Thực hiện logic gọi API dựa trên apiInfo.
            // Sử dụng APINetwork để gửi yêu cầu và cập nhật speaker sau khi nhận phản hồi.
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
        self.speaker = speaker
    }

    func adjustVolume(volumeValue: Int) {
        speaker.volume = volumeValue
    }

    func updateMuteState(isMute: Bool) {
        speaker.isMute = isMute
    }

    func updateConnection(type: ConnectionType) {
        speaker.connectionType = type
    }
}
