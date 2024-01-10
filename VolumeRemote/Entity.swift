//
//  Entity.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation

//entity sink interacter data to update stores

enum ConnectionType: Int {
    case D2D = 0
    case D2S
}

struct Speaker {
    var id: String?
    var volume: Int?
    var isMute: Bool?
    var connectionType: ConnectionType?
    
    init(id: String? = nil, volume: Int? = nil, isMute: Bool? = nil, connectionType: ConnectionType? = nil) {
        self.id = id
        self.volume = volume
        self.isMute = isMute
        self.connectionType = connectionType
    }
}

protocol SpeakerProtocol: AnyObject {
    static var speaker: Speaker {get set}
    func getSpeaker() -> Speaker
    func updateSpeaker(with speaker:Speaker)
}



class SpeakerManager {
    static let shared = SpeakerManager()
    
    private var speaker: Speaker
    
    private init() {
        speaker = Speaker(id: "default", volume: 5, isMute: false, connectionType: ConnectionType.D2S)        
    }
    
    func getSpeaker() -> Speaker {
//        print("get speaker from SpeakerManager")
        return speaker
    }
    
    func setSpeaker(speaker: Speaker) {
        self.speaker = speaker
    }
    
    func updateSpeaker(with speaker:Speaker){
        self.speaker.id = speaker.id ?? self.speaker.id
        self.speaker.volume = speaker.volume ?? self.speaker.volume
        self.speaker.isMute = speaker.isMute ?? self.speaker.isMute
        self.speaker.connectionType = speaker.connectionType ?? self.speaker.connectionType
        
//        print(self.speaker)
    }
    
    
}



//let speaker = SpeakerManager.shared.getSpeaker()
//print(speaker.id)  // In ra "default"
//
//SpeakerManager.shared.setSpeaker(speaker: Speaker(id: "new-speaker", volume: 75, isMute: true))
//let updatedSpeaker = SpeakerManager.shared.getSpeaker()
//print(updatedSpeaker.id)  // In ra "new-speaker"
