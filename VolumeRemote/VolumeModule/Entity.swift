//
//  SpeakerModel.swift
//  VolumeRemote
//
//  Created by Huan Le A. on 11/01/2024.
//

import Foundation

struct Speaker {
    var id: String = "1"
    var volume: Int?
    var isMute: Bool?
    var connectionType: ConnectionType? = .D2S
}

enum ConnectionType: Int {
    case D2D = 0
    case D2S
}

enum VolumeEvent {
    case volumeHasUpdated
    case muteStateHasUpdated
}
