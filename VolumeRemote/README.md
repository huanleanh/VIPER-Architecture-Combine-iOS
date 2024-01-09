

import Foundation
import Combine
@testable import SPKController

final class MockOCFManager: IOCFManager {
    lazy var ocfResources: [String: IOCFProcess] = OCFManager.ocfResources()
    var fakeSb: IFakeSoundbar
    
    init(fakeSb: IFakeSoundbar) {
        self.fakeSb = fakeSb
    }
    
    func initializer() {
        
    }
    
    func released() {
        
    }
    
    func startMonitoring(speaker: ISpeaker) -> Bool {
        return false
    }
    
    func stopMonitoring(speaker: ISpeaker) {
        
    }
    
    func observerDeviceEvent(deviceId: String) {
        
    }
    
    func stopObservingDeviceEvent() {
        
    }
    
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>? {
        switch apiInfo.method {
        case .GET:
            return get(speaker: speaker, apiInfo: apiInfo)
        case .SET:
            return set(speaker: speaker, apiInfo: apiInfo)
        default:
            return nil
        }
    }
    
    func get(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {
        let fakeSbResponse = fakeSb.getRemoteAttribute(uri: apiInfo.uri)
        let response = OCFResponse(speaker: speaker, apiInfo: apiInfo, uri: apiInfo.uri, attr: fakeSbResponse.attr, result: fakeSbResponse.result)
        if let ocfProcess = ocfResources[apiInfo.uri] {
            ocfProcess.handle(response: response)
        }
        return Just(response)
            .setFailureType(to: OCFError.self)
            .eraseToAnyPublisher()
    }
    
    func set(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {
        let attr = OCFHelper.convertToAttributes(params: apiInfo.params)
        let fakeSbResponse = fakeSb.setRemoteAttribute(uri: apiInfo.uri, attr: attr)
        let response = OCFResponse(speaker: speaker, apiInfo: apiInfo, uri: apiInfo.uri, attr: fakeSbResponse.attr, result: fakeSbResponse.result)
        if let ocfProcess = ocfResources[apiInfo.uri] {
            ocfProcess.handle(response: response)
        }
        return Just(response)
            .setFailureType(to: OCFError.self)
            .eraseToAnyPublisher()
    }
    
    func makeResources(speaker: VLSpeaker) -> [String: VLOcfResource] {
        return [:]
    }
}


/////

import Foundation
@testable import SPKController

final class MockURLProtocol: URLProtocol {
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        // if we have a valid URL…
        if let url = request.url {
            // …and if we have test data for that URL…
            if let data = self.getData(url: url) {
                // …load it immediately.
                self.client?.urlProtocol(self, didLoad: data)
            }
            
            // …and we return our response if defined…
            if let response = self.getResponse(url: url) {
                self.client?.urlProtocol(self,
                                         didReceive: response,
                                         cacheStoragePolicy: .notAllowed)
            }
            
            // …and we return our error if defined…
            if let error = self.getError(url: url) {
                self.client?.urlProtocol(self, didFailWithError: error)
            }
        }
        
        // mark that we've finished
        self.client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        
    }
}

extension MockURLProtocol {
    func getData(url: URL) -> Data? {
        var fileName: String?
        let urlString = url.absoluteString
        if urlString.contains("usertype") {
            fileName = "bixby-usertype"
        } else if urlString.contains("/retrieve") {
            if urlString.contains("companion") {
                fileName = "bixby-retrieve_companion"
            } else {
                fileName = "bixby-retrieve"
            }
        } else if urlString.contains("/registration") {
            if urlString.contains("companion") {
                
            } else {
                fileName = "bixby-registration"
            }
        } else if urlString.contains("/tnc/optional") {
            fileName = "bixby-optionaltnc"
        } else if urlString.contains("/reset") {

        } else if urlString.contains("/unlink") {
            fileName = "bixby-unlink"
        }
        if let fileName = fileName {
            if let path = Bundle(for: MockURLProtocol.self).path(forResource: fileName, ofType: "json"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                return data
            }
        }
        return nil
    }
    
    func getResponse(url: URL) -> URLResponse? {
        guard let data = self.getData(url: url) else { return nil }
        let string = String(data: data, encoding: .utf8) ?? ""
        let response = URLResponse(url: url, mimeType: nil, expectedContentLength: string.count, textEncodingName: string)
        return response
    }
    
    func getError(url: URL) -> Error? {
        return nil
    }
}



///

import Foundation
import SCClient
import Combine
import PluginPlatformDependencies
@testable import SPKController

protocol IFakeSoundbarResponse {
    var uri: String? { get set }
    var attr: OBJC_RCSResourceAttributes? { get set }
    var result: OBJC_eOCFResult { get set }
}

struct FakeSoundbarResponse: IFakeSoundbarResponse {
    var uri: String?
    var attr: OBJC_RCSResourceAttributes?
    var result: OBJC_eOCFResult = .OK
}

protocol IFakeOCFAction {
    func getRemoteAttribute(uri: String) -> IFakeSoundbarResponse
    func setRemoteAttribute(uri: String, attr: OBJC_RCSResourceAttributes) -> IFakeSoundbarResponse
    func getProcessData(uri: String) -> [String: Any]
    func setProcessData(uri: String, attr: OBJC_RCSResourceAttributes) -> [String: Any]
}

struct FakeD2DActionResponse {
    var method: String?
    var responseNode: AEXMLElement?
}

protocol IFakeD2DAction {
    func d2dDataProcess(actionMethod: String) -> FakeD2DActionResponse?
    func d2dDataAction(action: String, userId: String) -> Data?
}

protocol IFakeSoundbar: IFakeOCFAction, IFakeD2DAction {
    var data: ISpeaker { get set }
    var isAISoundbar: Bool { get set }
}

extension IFakeSoundbar {
    func getRemoteAttribute(uri: String) -> IFakeSoundbarResponse {
        let response = self.getProcessData(uri: uri)
        return FakeSoundbarResponse(
            uri: uri,
            attr: OCFHelper.convertToAttributes(params: response),
            result: .OK
        )
    }
    
    func setRemoteAttribute(uri: String, attr: OBJC_RCSResourceAttributes) -> IFakeSoundbarResponse {
        let response = self.setProcessData(uri: uri, attr: attr)
        return FakeSoundbarResponse(
            uri: uri,
            attr: OCFHelper.convertToAttributes(params: response),
            result: .OK
        )
    }
    
    func getProcessData(uri: String) -> [String: Any] {
        var responseData: [String: Any] = [:]
        switch uri {
        case VLOcfConst.URI_SOUNDMODE:
            responseData = [
                VLOcfConst.ATTR_AI_SOUNDMODE_SUPPORTED: data.soundModeResponse.modesList,
                VLOcfConst.ATTR_SOUNDMODE: data.soundModeResponse.selectedMode
            ]
        case VLOcfConst.URI_AI_LIGHTINGMODE:
            responseData = [
                VLOcfConst.ATTR_AI_LIGHTINGMODE_SUPPORTED: data.lightingModeResponse.isSupported,
                VLOcfConst.ATTR_AI_LIGHTINGMODE_CURRENTMODE: data.lightingModeResponse.selectedMode,
                VLOcfConst.ATTR_AI_LIGHTINGMODE_LIST: data.lightingModeResponse.modesList
            ]
        case VLOcfConst.URI_AI_USBMODE:
            responseData = [
                VLOcfConst.ATTR_AI_USBMODE_SUPPORTED: data.usbModeResponse.isSupported,
                VLOcfConst.ATTR_AI_USBMODE_CURRENTMODE: data.usbModeResponse.selectedMode,
                VLOcfConst.ATTR_AI_USBMODE_LIST: data.usbModeResponse.modesList
            ]
        case VLOcfConst.URI_AI_SPEAKER_HEADSET_MODE:
            responseData = [
                VLOcfConst.ATTR_AI_SPEAKER_HEADSET_MODE_SUPPORTED: data.speakerHeadsetModeResponse.isSupported,
                VLOcfConst.ATTR_AI_SPEAKER_HEADSET_MODE_CURRENTSPEAKER: data.speakerHeadsetModeResponse.selectedMode,
                VLOcfConst.ATTR_AI_SPEAKER_HEADSET_MODE_LIST: data.speakerHeadsetModeResponse.modesList
            ]
        case VLOcfConst.URI_CUSTOM_SETTINGS:
            responseData = data.customSettings.dictionary ?? [:]
        case VLOcfConst.URI_AI_ADVANCEDAUDIO:
            responseData = [
                VLOcfConst.ATTR_AI_ADVANCEDAUDIO_VOICEAMPLIFIER: data.advancedAudio.voiceAmplifier,
                VLOcfConst.ATTR_AI_ADVANCEDAUDIO_BASSBOOST: data.advancedAudio.bassBoost,
                VLOcfConst.ATTR_AI_ADVANCEDAUDIO_NIGHTMODE: data.advancedAudio.nightMode
            ]
        case VLOcfConst.URI_NETWORKINFO:
            responseData = [
                VLOcfConst.ATTR_NETWORKINFO: [
                    "connectionType": "wireless",
                    "ch": 1,
                    "wifidirectssid": "I’m Soundbar Q990C",
                    "wifidirectch": 1,
                    "rssi": 3,
                    "bssid": "4e:c6:13:aa:b2:48",
                    "ssid": "Ahihi",
                    "ip": "192.168.220.192"
                ],
                VLOcfConst.ELEMENT_BSSID: "4e:c6:13:aa:b2:48",
                VLOcfConst.ELEMENT_IP: "192.168.220.192"
            ]
        case VLOcfConst.URI_AUDIO_PROMPT:
            responseData = [
                VLOcfConst.ATTR_AUDIO_PROMPT: data.audioPrompt.audioUI,
                VLOcfConst.ATTR_AUDIO_PROMPT_LIST: data.audioPrompt.audioUILanguageList.map { $0.code },
                VLOcfConst.ATTR_AUDIO_PROMPT_LANGUAGE: data.audioPrompt.audioUILanguage.code
            ]
        case VLOcfConst.URI_INSTALLATIONTYPE:
            responseData = [
                VLOcfConst.ATTR_INSTALLATIONTYPE: data.installationType.rawValue
            ]
        case VLOcfConst.URI_AI_BIXBY_ON_BOARDING:
            do {
                let provisioning = try JSONEncoder().encode(data.bixbyOnboarding.provisioning)
                responseData = [
                    VLOcfConst.ATTR_AI_BIXBY_ON_BOARDING: data.bixbyOnboarding.isOnboardingDone,
                    VLOcfConst.ATTR_AI_BIXBY_PROVISIONING: provisioning
                ]
            } catch {
                responseData = [
                    VLOcfConst.ATTR_AI_BIXBY_ON_BOARDING: data.bixbyOnboarding.isOnboardingDone,
                    VLOcfConst.ATTR_AI_BIXBY_PROVISIONING: [:]
                ]
            }
        default:
            break
        }
        return responseData
    }
    
    func d2dDataProcess(actionMethod: String) -> FakeD2DActionResponse? {
        return nil
    }
    
    func d2dDataAction(action: String, userId: String) -> Data? {
        guard let url = URLComponents(string: action) else { return nil }
        guard let param = url.queryItems?.first else { return nil }
        guard let actionXML = param.value?.data(using: .utf8) else { return nil }
        let actionNode = try? AEXMLDocument(xml: actionXML)
        guard let actionMethod = actionNode?.children.first?.value else { return nil }
        
        guard let response = d2dDataProcess(actionMethod: actionMethod) else { return nil }
        guard let method = response.method,
              let dataResponseNode = response.responseNode else { return nil }
        
        let doc = AEXMLDocument()
        let uicNode = AEXMLElement(name: "UIC")
        let methodNode = AEXMLElement(
            name: "method",
            value: method
        )
        let userIdNode = AEXMLElement(
            name: D2DConstant.Node.userId,
            value: userId
        )
        let responseNode = AEXMLElement(
            name: "response",
            attributes: ["result": "ok"]
        )
        responseNode.addChild(dataResponseNode)
        uicNode.addChildren([methodNode, userIdNode, responseNode])
        doc.addChild(uicNode)
        
        let xml = doc.xml
        return xml.data(using: .utf8)
    }
}
////

import Foundation
import PluginPlatformDependencies
@testable import SPKController

final class FakeSpeaker: ISpeaker {
    var uuid: String = UUID().uuidString
    
    var scDevice: ScDeviceProtocol = MockScDevice(sb: nil, deviceCloud: nil)
    
    var ocfResources: Dictionary<String, VLOcfResource> = [:]
    
    var propertyOptions: VLSpeakerPropertyOptions = .aiMaster
    
    // MARK: - ISpkVoiceAssistants
    var va: VLSpkVA = VLSpkVA()
    var alexa: VLSpkAlexa = VLSpkAlexa()
    var bixbyOnboarding: VLSpkBixbyOnboarding = VLSpkBixbyOnboarding()
    var bixbySettings: VLSpkBixbySettings = VLSpkBixbySettings()
    private(set) var googleAssistant: GoogleAssist = GoogleAssist()
    var AI_SHOW_BIXBY = false

    // MARK: - ISpkCustomSettings
    var customSettings: VLSpkCustomSettings = VLSpkCustomSettings()

    // MARK: - Hidden Menu DownloadableApp
    var downloableApp: DownloadableAppModel = DownloadableAppModel()

    // MARK: - Hidden Menu SesInfo
    var sesInfo: SesInfoModel = SesInfoModel()

    // MARK: - Hidden Menu InfoLink
    var infoLink: InfoLinkModel = InfoLinkModel()

    // MARK: - ISpkInfo
    var oicp: ISpkOICP = VLSpkOICP()
    private var _name: String! = nil
    var name: String = "<unknown>"

    var softwareVersion: String = "<unknown>"
    var micomVersion: String = "<unknown>"

    var dialVersion: String = "<unknown>"
    var modelName = ""
    var protocolVersion: Float = 0
    var appIpInfoDict: [String: String] = [:]
    var isAISoundbar: Bool = true

    // MARK: - ISpkGroup
    private(set) var groupInfo = VLGroupInfo()
    var groupCandidates = [VLGroupInfo]()
    var groupSlaves = [VLGroupInfo]()

    // MARK: - ISpkWoofer
    var wooferFeature = VLWooferFeature.off
    var wooferIsConnected = false
    private(set) var wooferLevel: VLAsyncValue<Int> = VLAsyncValue<Int>()
    
    // MARK: - IFeatureSupport
    var installationType: InstallationTypeEnum = .None
    var isSupportInstallationType: Int = 0
    var isSupportDialController: Int = 0
    var isSupportAudioPrompt: Int = 0

    // MARK: - ISpkEqualizer
    var spkEQ: VLSpkEqualizer = VLSpkEqualizer()

    // MARK: - ISpkSTHub
    var stHub: speakerSTHub = speakerSTHub()

    // MARK: - ISpkFunction
    var function: VLSpeakerFunction = .none

    // MARK: - ISpkNetwork
    var ip: String? = "192.168.1.104"
    var macAddr: String = "<unknown>"
    var iotDeviceId: String?
    var ssid: String = ""
    var bssid_ip: (bssid: String, ip: String) = ("", "")
    var mac: String = ""
    var networkStatus: SpkNetworkStatus = SpkNetworkStatus()
    var rssi: Int = -1
    var ch: Int = -1
    var wifiDirectSsid: String = ""
    var wifiDirectRssi: Int = -1
    var wifiDirectCh: Int = -1
    var networkStatusConnectionType: String = ""
    // D2S Properties
    var connectionType = ConnectionType.none
    var lastD2SVolumeSendTime: TimeInterval = 0
    var lastD2SVolume: Int32 = 0
    var btType: VLBTType = .none
    var alive = true
    var numOfChannel: Int = 0
    var numOfHdmi = 0
    var lastConnectionType: String?
    var btPairingModeStatus: Bool?
    var btAppReadyStatus: Bool?
    var btMacAdd: String?
    var hardwareUniqueID: String?
    var zigbeeMacAddress: String?
    var aiPlayer: AIPlayers?
    var wifiMacAddr: String?
    var functionConnectionState = false
    var connectedDeviceName = ""
    var usbExsistFiles = false
    var isNetworkStrengthWeak: Bool {
        if self.networkStatus.rssi <= 1 && self.networkStatus.networkStatusConnectionType == "wireless" {
            return true
        }
        return false
    }
    
    var dialController: Bool = false
    
    var autoPowerDown: Bool = false

    // MARK: - ISpkPassThrough
    var passThroughState: Bool?
    
    // MARK: - ISpkSoundMode
    var soundModeResponse: BaseListResponse = BaseListResponse()
    
    // MARK: - ILightingMode
    var lightingModeResponse: BaseListResponse = BaseListResponse()
    
    // MARK: - IUSBMode
    var usbModeResponse: BaseListResponse  = BaseListResponse()
    
    // MARK: - ISpeakerHeadsetMode
    var speakerHeadsetModeResponse: BaseListResponse  = BaseListResponse()
    
    // MARK: - ISpkHelper
    var helperVar: VLHelperSpeakerVariables = VLHelperSpeakerVariables()
    
    // MARK: - ISpkAdvancedAudio
    var advancedAudio: VLSpkAdvancedAudio
    
    // MARK: - IAudioPrompt
    var audioPrompt: AudioPrompt
    
    init(connectionType: ConnectionType = .d2s) {
        self.connectionType = connectionType
        // Sound mode
        self.soundModeResponse = BaseListResponse(
            _modeList: [FakeSpeaker.defaultSoundMode, "surround", "smart", "game", "adaptive sound", "adaptive sound+", "music"],
            _selectedMode: FakeSpeaker.defaultSoundMode,
            _isSupported: true
        )
        
        // Lighting mode
        self.lightingModeResponse = BaseListResponse(
            _modeList: [FakeSpeaker.defaultLightingMode, "BBB", "CCC", "DDD", "EEE", "FFF"],
            _selectedMode: FakeSpeaker.defaultLightingMode,
            _isSupported: true
        )
        
        // USB Mode
        self.usbModeResponse = BaseListResponse(
            _modeList: [FakeSpeaker.defaultUSBMode, "USBMode1", "USBMode2", "USBMode3", "USBMode4", "USBMod5"],
            _selectedMode: FakeSpeaker.defaultUSBMode,
            _isSupported: true
        )
        
        // HeadSet Mode
        self.speakerHeadsetModeResponse = BaseListResponse(
            _modeList: [FakeSpeaker.defaultHeadSetMode, "HeadSetMode1", "HeadSetMode2", "HeadSetMode3", "HeadSetMode4", "HeadSetMode5"],
            _selectedMode: FakeSpeaker.defaultHeadSetMode,
            _isSupported: true
        )
        
        // Custom Settings
        if let path = Bundle(for: FakeCusSettingsSoundbar.self).path(forResource: "customsettings", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            do {
                let newData = try JSONDecoder().decode(VLSpkCustomSettings.self, from: data)
                self.customSettings = newData
            } catch {
                MALOG("ererewrerere \(error)")
            }
        }
        
        // Audio prompt
        self.audioPrompt = AudioPrompt(audioUI: true,
                                       audioUILanguage: AudioPromptLanguage(code: "ENG"),
                                       audioUILanguageList: [AudioPromptLanguage(code: "ENG"),
                                                             AudioPromptLanguage(code: "KOR"),
                                                             AudioPromptLanguage(code: "DEU")])
        
        // Advanced Sound Settings
        self.advancedAudio = VLSpkAdvancedAudio(voiceAmplifier: 1, bassBoost: 1, nightMode: 1)
        
        // Bixby Onboarding
        let stringJson =    """
                            {
                                "countrycode" : "VN",
                                "cur_user_params" :
                                    "{
                                        \"user_id\":\"shrc.ios.av@gmail.com\",
                                        \"api_domain\":\"https://us-auth2.samsungosp.com\",
                                        \"ssp_domain\":\"https://us-auth2.samsungosp.com\",
                                        \"access_token_time\":\"1679550453\",
                                        \"refresh_token_time\":\"1687240053\",
                                        \"not_exist\":\"false\",
                                        \"blocked\":\"false\",
                                        \"blocked_by\":\"\"
                                    }",
                                "currentvoicelanguage" : "en_US",
                                "deviceName" : "QSoundbar",
                                "device_params" :
                                    "{
                                        \"mcc\":\"452\",
                                        \"device_id\":\"1935994711264b9362b3c174f07bea1c4266350fe7fd0f161a0a222e67e37059\",
                                        \"svr_type\":\"STG\",
                                        \"device_cog\":\"https://stg-use2-user.stg-aibixby.com\",
                                        \"vd_bac\":\"https://eng-usw2-bac-vd.dev-aibixby.com\",
                                        \"provisioning\":\"https://provisioning-use2.mgmt.stg-aibixby.com\",
                                        \"assistant_home\":\"https://ash-use2.mgmt.stg-aibixby.com\",
                                        \"marketplace\":\"https://market-use2.mgmt.stg-aibixby.com\",
                                        \"pdss\":\"https://pdss-sync-stg.stg-aibixby.com\",
                                        \"lang\":\"en_US\",
                                        \"bixby_on\":\"on\",
                                        \"svoice_on\":\"off\"
                                    }",
                                "modelid" : "23_IMX8M_AISPK",
                                "svcId" : "STGVDSTVCAD9AFFCE6C34BDA956578ED6AEB0027"
                            }
                            """
        
        bixbyOnboarding = VLSpkBixbyOnboarding()
        do {
            let model = try JSONDecoder().decode(VLSpkBixbyProvisioning.self, from: Data(stringJson.utf8))
            self.bixbyOnboarding.provisioning = model
            self.bixbyOnboarding.registration.svcId = model.svcId
        } catch {
            self.bixbyOnboarding = VLSpkBixbyOnboarding()
        }
    }
    
    func notifyDispatcherOfType(_ type: String) {
        
    }
    
    func notifyOnMainQueueDispatcherOfType(_ type: String) {
        
    }
    
    func performGetAISoundBarSoundFrom() {
        
    }
    
    func performGetLastConnection() {
        
    }
    
    func performGetChannelVolume() {
        
    }
    
    func performGetShowAlexaInitialScreen() {
        
    }
    
    func performGetGroupCandidateList() {
        
    }
    
    func performGetGroupInfo() {
        
    }
    
    func performUngroup() {
        
    }
    
    func performGetWooferLevel() {
        
    }
    
    func performSetWooferLevel(_ value: Int) {
        
    }
    
    func clear(options: SPKController.VLSpeakerPropertyOptions) {
        
    }
    
    func addInputSourceByName(_ sourceName: String, notAv: String, av: String) {
        
    }
}

extension FakeSpeaker {
    static var defaultSoundMode: String { "standard" }
    static var defaultLightingMode: String { "random" }
    static var defaultUSBMode: String { "DefaultUSBMode" }
    static var defaultHeadSetMode: String { "DefaultHeadSetMode" }
}



///

