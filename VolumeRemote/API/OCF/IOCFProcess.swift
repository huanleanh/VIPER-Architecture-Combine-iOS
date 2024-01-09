

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
