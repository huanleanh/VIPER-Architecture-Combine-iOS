//  ID2DProcess.swift - SPKController_2
//  Copyright © 2022 Samsung Electronics. All rights reserved.

import Foundation

protocol ID2DProcess {
    func processResponse(response: ID2DResponse)
    func failedResponse(response: ID2DResponse)
}

extension ID2DProcess {
    func failedResponse(response: ID2DResponse) {
        MALOG("[D2DProcess] Missing implement code")
    }
}
