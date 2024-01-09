

import Foundation
import Combine

protocol ID2DManager {
    var errorCodeMap: VLErrorCodes { get }
    var d2dResources: [String: ID2DProcess] { get }
    
    func initializer()
    func released()
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo)
}

struct D2DConstant {
    enum MethodName: String {
        case kBtDialControllerStatus = "BtDialControllerStatus"
        case kAutoPowerDownInAux = "AutoPowerDownInAux"
        case kInstallationType = "InstallationType"
        case kSoundmode = "SoundMode"
        case k7bandEQList = "7BandEQList"
        case k7bandEQMode = "7bandEQMode"
        case k7bandEQValue = "7bandEQValue"
        case kReset7BandEQValue = "Reset7bandEQValue"
        case kCurrentEQMode = "CurrentEQMode"
        case kAddCustomEQMode = "AddCustomEQMode"
        case kDelCustomEQMode = "DelCustomEQMode"
        case kEQMode = "EQMode"
        case kEQBass = "EQBass"
        case kEQTreble = "EQTreble"
        case kEQMenu = "EQMenu"
        case kNetworkStatus = "ApInfo"
        case kAudioPrompt = "AudioUI"
        case kAudioPromptLanguageList = "AudioPromptLanguageList"
        case kAudioPromptLanguage = "AudioPromptLanguage"
        case kFeature = "Feature"
    }

    enum XMLResult: String {
        case XMLResultKey = "result"
        case XMLResultOK = "ok"
    }
    
    struct Node {
        static var uicError: String { "errCode" }
        static var cpmError: String { "errcode" }
        static var errorMessage: String { "errmessage" }
        static var userId: String { "user_identifier" }
        //Network Status
        static var soundMode: String { "soundMode" }
        static var ssid: String { "ssid" }
        static var mac: String { "mac" }
        static var rssi: String { "rssi" }
        static var ch: String { "ch" }
        static var wifidirectssid: String { "wifidirectssid" }
        static var wifidirectrssi: String { "wifidirectrssi" }
        static var wifidirectch: String { "wifidirectch" }
        static var connectiontype: String { "connectiontype" }
        //EQ
        static var presetListCount: String { "presetlistcount" }
        static var presetList: String { "presetlist" }
        static var presetIndex: String { "presetindex" }
        static var presetName: String { "presetname" }
        static var eqValue: String { "eqvalue" }
        static var eqMenu: String { "eqmenu" }
        static var eqBass: String { "eqbass" }
        static var eqTreble: String { "eqtreble" }
    }
}

final class D2DManager: ID2DManager {
    private let queue: DispatchQueue = DispatchQueue(label: "com.queue.D2DManager")
    private var networkManager: INetworkManager { AVEngine.shared.avManagers.networkManager }
    private var speakerManager: VLSpeakerManager { AVEngine.shared.avManagers.speakerManager }
    private var cancellable: AnyCancellable?
    
    private(set) var errorCodeMap: VLErrorCodes = VLErrorCodes()
    lazy var d2dResources: [String: ID2DProcess] = D2DManager.d2dResources()
    
    func initializer() {
        cancellable?.cancel()
        cancellable = networkManager.networkManagerResponse
            .sink(receiveValue: weakify(self, execution: { owner, response in
                MALOG("[D2DManager] Network mnager response \(response)")
                switch response {
                case .didReceiveData(let data, let host):
                    owner.didReceiveData(data: data, host: host)
                case .didDisconect(let host):
                    owner.didDisconect(host: host)
                case .connectedChanged(_, _):
                    break
                }
            }))
    }
    
    func released() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) {
        MALOG("[D2DManager] apiRequest speaker:\(speaker), apiInfo:\(apiInfo)")
        guard let ip = speaker.ip else {
            MALOG("[D2DManager] Fail to send XML. IP is nil for [\(speaker)]")
            return
        }
        networkManager.sendAction(apiInfo.xmlString, toHost: ip, uuid: speaker.uuid)

        MALOG("[D2DManager] UUID:\(VLModelStore.appUUID)\n>>> send XML:\(speaker)\n[spkcmd]\(apiInfo.xmlString)")
    }
}

// MARK: - Handle NetworkManagerResponse
extension D2DManager {
    private func didReceiveData(data: Data, host: String) {
        guard let speaker = speakerManager.speaker(ip: host) else {
            MALOG("[D2DManager] receiveData but speaker not found!!! ip : \(host)")
            return
        }
        guard var xmlString = String(bytes: data.bytes, encoding: .utf8) else {
            MALOG("[D2DManager] !!! receive data to string in nil for speaker:\(speaker)")
            return
        }
        MALOG("\n[D2DManager] <<< receive XML:\(speaker)\n[spkcmd]\(xmlString)")
        xmlString = xmlString.replacingOccurrences(of: "&#x0A", with: "&amp;#x0A")
        xmlString = xmlString.replacingOccurrences(of: "&#x08", with: "&amp;#x08")

        guard let data = xmlString.data(using: .utf8) else {
            MALOG("[D2DManager] !!! receive xml DATA is nil for speaker:\(speaker)")
            return
        }
        guard let xmlDoc = VLXMLDocument.new(with: data) else { return }
        guard let rootNode = xmlDoc.rootNode() else { return }
        let responseNode = rootNode.subNodesInAllLevels(forName: "response").last as? VLXMLNode
        let asyncResponseNode = rootNode.subNodesInAllLevels(forName: "async_response").last as? VLXMLNode
        guard let xmlNode = responseNode ?? asyncResponseNode else { return }
        guard let methodName = methodNameForXMLNode(rootNode) else { return }
        guard let process = getD2DProcess(methodName) else {
            MALOG("[D2DManager] !!! HANDLER NOT FOUND !!! methodName:\(methodName)")
            return
        }
        
        let userID = rootNode.text(forSubNodeName: D2DConstant.Node.userId) != nil ? rootNode.text(forSubNodeName: D2DConstant.Node.userId) ?? "" : ""
        let myUserId = VLModelStore.appUUID
        let responseUser = userID == "public" ? VLResponseUser.responsePublic : userID == myUserId ? VLResponseUser.responseMe : VLResponseUser.responseOther
        let subSystem = subsystemForXMLDocument(xmlDoc)
        speaker.alive = true
        
        let isExecute = (speaker.bssidNotSame && methodName == "MainInfo") || speaker.bssidNotSame == false
        if isExecute {
            let response = D2DResponse(speaker: speaker, method: methodName, userID: userID, subSystem: subSystem, responseUser: responseUser, xmlNode: xmlNode)
            if xmlNode.nodeAttribute(forKey: D2DConstant.XMLResult.XMLResultKey.rawValue) == D2DConstant.XMLResult.XMLResultOK.rawValue {
                MALOG("[D2DManager] Success Response Node")
                process.processResponse(response: response)
            } else {
                MALOG("[D2DManager] Failed Response Node")
                process.failedResponse(response: response)
                
                var action: String?
                var errorMessage = errorMessageForNode(xmlNode)
                if let errorCode = errorCodeForNode(xmlNode) {
                    action = self.errorCodeMap.actionForCode(errorCode)
                    if let plistMessage = self.errorCodeMap.messageForCode(errorCode) {
                        errorMessage = VLLocalizedString(plistMessage)
                    }
                }
                
                gcdAsyncOnMainQueue(weakify(self, execution: { owner in
                    if action == "default" {
                        VLGUIManager.showToast(errorMessage ?? VLLocalizedString("ST_COMMON_ERROR"))
                    }
                    MALOG("!!! ERROR !!! failedResponseNode Msg:\(String(describing: errorMessage)), Action:\(String(describing: action))")
                }))
            }
        }
    }
    
    private func didDisconect(host: String) {
        
    }
}

// MARK: - Private methods
extension D2DManager {
    private func methodNameForXMLNode(_ node: VLXMLNode) -> String? {
        guard let arr: Array = node.subNodesInAllLevels(forName: "method") else { return nil }
        let lastObj = arr.last as? VLXMLNode
        return lastObj?.nodeTextValue()
    }

    private func getD2DProcess(_ methodName: String) -> ID2DProcess? {
        return d2dResources[methodName]
    }

    private func subsystemForXMLDocument(_ doc: VLXMLDocument) -> VLSpeakerSubSystem {
        if let xmlNode = doc.rootNode(), let subSystem = xmlNode.nodeName(), subSystem == "UIC" {
            return .uic
        }
        return .cpm
    }

    private func errorMessageForNode(_ responseNode: VLXMLNode) -> String? {
        return responseNode.text(forSubNodeName: D2DConstant.Node.errorMessage)
    }

    private func errorCodeForNode(_ responseNode: VLXMLNode) -> String? {
        return responseNode.text(forSubNodeName: D2DConstant.Node.uicError) ?? responseNode.text(forSubNodeName: D2DConstant.Node.cpmError)
    }
}

// MARK: - Static methods
extension D2DManager {
    static func d2dResources() -> [String: ID2DProcess] {
        return [
            //EQ
            D2DConstant.MethodName.kSoundmode.rawValue: D2DSoundmodeProcess(),
            D2DConstant.MethodName.kReset7BandEQValue.rawValue: D2DReset7BandEQValueProcess(),
            D2DConstant.MethodName.k7bandEQList.rawValue: D2D7BandEQListProcess(),
            D2DConstant.MethodName.kCurrentEQMode.rawValue: D2DCurrentEQModeProcess(),
            D2DConstant.MethodName.k7bandEQMode.rawValue: D2DCurrentEQModeProcess(),
            D2DConstant.MethodName.kDelCustomEQMode.rawValue: D2DDelCustomEQModeProcess(),
            D2DConstant.MethodName.kAddCustomEQMode.rawValue: D2DAddCustomEQModeProcess(),
            D2DConstant.MethodName.kEQMenu.rawValue: D2DEQMenuProcess(),
            D2DConstant.MethodName.k7bandEQValue.rawValue: D2D7BandEQValueProcess(),
            D2DConstant.MethodName.kEQMode.rawValue: D2DEQModeProcess(),
            D2DConstant.MethodName.kEQBass.rawValue: D2DEQBassProcess(),
            D2DConstant.MethodName.kEQTreble.rawValue: D2DEQTrebleProcess(),
            //Network
            D2DConstant.MethodName.kNetworkStatus.rawValue: D2DNetworkStatusProcess(),
            //AudioPrompt
            D2DConstant.MethodName.kAudioPrompt.rawValue: D2DAudioPromptProcess(),
            D2DConstant.MethodName.kAudioPromptLanguageList.rawValue: D2DAudioPromptLanguageListProcess(),
            D2DConstant.MethodName.kAudioPromptLanguage.rawValue: D2DAudioPromptLanguageProcess(),
            D2DConstant.MethodName.kBtDialControllerStatus.rawValue: D2DDialControllerStatusProcess(),
            D2DConstant.MethodName.kAutoPowerDownInAux.rawValue: D2DAutoPowerDownProcess(),
            D2DConstant.MethodName.kInstallationType.rawValue: D2DInstallationTypeProcess(),
            D2DConstant.MethodName.kFeature.rawValue: D2DFeatureProcess()
        ]
    }
}
