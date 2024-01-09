

import Foundation

enum OCFErrorCode: Int {
    case objReleased = 99999
    case ocfDeviceNil = 99998
    case remoteAttributeFailed = 99997
    case ocfSlaverIgnored = 99996
}

struct OCFError: Error {
    var errorCode: Int
}
