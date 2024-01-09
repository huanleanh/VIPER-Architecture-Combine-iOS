//  OCFProcess.swift - SPKController_2
//  Copyright © 2022 Samsung Electronics. All rights reserved.

import Foundation
import Combine
import SCClient

protocol IOCFProcess {
    func handle(response: IOCFResponse)
    func failedHandle(response: IOCFResponse, error: OCFError?)
}

extension IOCFProcess {
    func failedHandle(response: IOCFResponse, error: OCFError?) {
        MALOG("[AVPlugin][IOCFProcess] Implement failedHandle func if needed")
    }
}
