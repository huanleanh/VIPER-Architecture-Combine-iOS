//  D2DResponse.swift - SPKController_2
//  Copyright © 2022 Samsung Electronics. All rights reserved.

import Foundation

protocol ID2DResponse {
    var speaker: ISpeaker { get set }
    var method: String { get set }
    var userID: String { get set }
    var subSystem: VLSpeakerSubSystem { get set }
    var responseUser: VLResponseUser { get set }
    var xmlNode: VLXMLNode { get set }
}

struct D2DResponse: ID2DResponse {
    var speaker: ISpeaker
    var method: String
    var userID: String
    var subSystem: VLSpeakerSubSystem
    var responseUser: VLResponseUser
    var xmlNode: VLXMLNode
}
