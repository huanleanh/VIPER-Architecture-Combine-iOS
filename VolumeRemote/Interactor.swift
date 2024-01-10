//
//  Interactor.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation

protocol InteractorProtocol: AnyObject {
    var speakerEntity: Speaker {get}
    func makeAdjustVolumeRequest(volumeValue: Int)
    func makeUpdateMuteStateRequest(isMute: Bool)
    func updateConnection(type: ConnectionType)
}

class Interactor: InteractorProtocol {
    var speakerEntity: Speaker {return SpeakerManager.shared.getSpeaker()}
    func makeAdjustVolumeRequest(volumeValue: Int) {
        print("I: adjust volume")
        let speaker = SpeakerManager.shared
        APINetwork().apiRequest(speaker: speaker, apiInfo: APIInfo.init(cases: .setVolume, volume: volumeValue))
        SpeakerManager.shared.updateSpeaker(with: Speaker(volume: volumeValue))
    }
    
    func makeUpdateMuteStateRequest(isMute: Bool) {
        let speaker = SpeakerManager.shared
        APINetwork().apiRequest(speaker: speaker, apiInfo: APIInfo.init(cases: .setMute, isMute: isMute) )
        SpeakerManager.shared.updateSpeaker(with: Speaker(isMute: isMute))
    }
    
    func updateConnection(type: ConnectionType) {
        SpeakerManager.shared.updateSpeaker(with: Speaker(connectionType: type))
    }
    
    weak var presenter: PresenterProtocol?
    
}
