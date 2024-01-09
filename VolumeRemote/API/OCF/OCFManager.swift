

import Foundation
import Combine

protocol IOCFManager {
    var ocfResources: [String: IOCFProcess] { get }
    
    func initializer()
    func released()
    
    func startMonitoring(speaker: ISpeaker) -> Bool
    func stopMonitoring(speaker: ISpeaker)
    func observerDeviceEvent(deviceId: String)
    func stopObservingDeviceEvent()
    
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>?
    func get(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>
    func set(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>
    
    //Old func, will be removed when completed
    func makeResources(speaker: VLSpeaker) -> [String: VLOcfResource]
    
    var pluginStateConnected: CurrentValueSubject<Bool, Never> { get set }
}

final class OCFManager: IOCFManager {
    static let volumeReceiveDelay: TimeInterval = 10.0    //Follow Android D2S spec
    private let queue: DispatchQueue = DispatchQueue(label: "com.queue.ocfManager", attributes: .concurrent)
    private var lifeTime = Lifetime.make()
    private var store: DevicesStore?
    private lazy var cancellables = Set<AnyCancellable>()
    private var avEngine: IAVEngine { return AVEngine.shared }
    private var speakerManager: VLSpeakerManager { return AVEngine.shared.avManagers.speakerManager }
    private var unknownStatetimer: Timer?
    private var pluginState: PluginIotivityConnectionState?
    private var cloudDevState: OBJC_eCloudDeviceState?
    
    deinit {
        released()
    }
    
    func initializer() {
//        released()
    }
    lazy var ocfResources: [String: IOCFProcess] = OCFManager.ocfResources()
    
    func released() {
        if cancellables.isEmpty == false {
            cancellables.forEach { $0.cancel() }
            cancellables.removeAll()
        }
        if let speaker = speakerManager.selectedSpeaker {
            self.stopMonitoring(speaker: speaker)
        }
        self.stopObservingDeviceEvent()
        lifeTime.token.dispose()
        lifeTime = Lifetime.make()
        unknownStatetimer?.invalidate()
        unknownStatetimer = nil
    }
     var pluginStateConnected: CurrentValueSubject<Bool, Never> = CurrentValueSubject(true)
    
    func apiRequest(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError>? {
//        MALOG("[OCFManager] apiRequest speaker:\(speaker), apiInfo:\(apiInfo)")
        switch apiInfo.method {
        case .GET:
            return self.get(speaker: speaker, apiInfo: apiInfo)
        case .SET:
            return self.set(speaker: speaker, apiInfo: apiInfo)
        default:
            return nil
        }
    }
    
    func startMonitoring(speaker: ISpeaker) -> Bool {
        if avEngine.isAISoundbar {
            lifeTime.token.dispose()
            lifeTime = Lifetime.make()
            avEngine.stEngine.connectionStateProvider?
                .pluginConnectionStateChangeSignal
                .take(during: lifeTime.lifetime)
                .observeValues(weakify(self, execution: { owner, connectionState in
                    MALOG("[OCFManager] cloud connected change status = \(connectionState)")
                    guard let spk = owner.avEngine.avManagers.speakerManager.selectedSpeaker else { MALOG("speaker is null in cloud connected change")
                        return }
                    if owner.pluginState == nil || owner.pluginState != connectionState {
                        owner.pluginState = connectionState
                        // Connected : Disconnected
                        owner.pluginStateConnected.send(owner.pluginState != .disconnected)
                        connectionState == .connected ? owner.subscribe(speaker: spk) : owner.unsubscribe(speaker: spk)
                        if connectionState == .disconnected && AVEngine.shared.isAISoundbar {
                            VLGUIManager.shared.visibaleOfflineStatusSignal.send(true)
                        }
                    }
                }))
            
            NotificationCenter.default.publisher(for: .OCFDeviceIsReady)
                .sink(receiveValue: weakify(self, execution: { owner, notification in
                    owner.OCFDeviceIsReady(notification: notification)
                }))
                .store(in: &cancellables)
            NotificationCenter.default.publisher(for: .OCFDeviceIsNotReady)
                .sink(receiveValue: weakify(self, execution: { owner, notification in
                    owner.OCFDeviceIsNotReady(notification: notification)
                }))
                .store(in: &cancellables)
        }
        
        return speaker.scDevice.startCloudDeviceMonitoring {
            [weak self] (uri: String?, state: OBJC_eCloudDeviceState, result: OBJC_eOCFResult) in
            guard let self = self else { return }
            MALOG("[OCFManager] startCloudDeviceMonitoring, [url:\(String(describing: uri)), state:\(state.rawValue), result:\(result) , \(speaker.name)")
            switch state {
            case .UNKNOWN:
                let context: [String: Any] = ["speaker": speaker, "state": state]
                self.unknownStatetimer?.invalidate()
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.unknownStatetimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(self.fireTimer), userInfo: context, repeats: false)
                }
            default:
                self.subscribeUnsubscribeOnStateChange(state: state, speaker: speaker)
            }
        }
    }
    
    @objc private func fireTimer(timer: Timer) {
            guard let context = timer.userInfo as? [String: Any] else { return }
            let _speaker: VLSpeaker? = context["speaker"] as? VLSpeaker
            let _state: OBJC_eCloudDeviceState? = context["state"] as? OBJC_eCloudDeviceState
            guard let state = _state, let speaker = _speaker else {
                MALOG("speaker or state is nil")
                return
            }
            subscribeUnsubscribeOnStateChange(state: state, speaker: speaker)
        }
        
        private func subscribeUnsubscribeOnStateChange(state: OBJC_eCloudDeviceState, speaker: ISpeaker) {
            unknownStatetimer?.invalidate()
            if (speaker.scDevice.getCloudDevice()?.deviceId != AVEngine.shared.avManagers.speakerManager.selectedSpeaker?.scDevice.getCloudDevice()?.deviceId) {
                subscribe(speaker: speaker)
            } else {
                if cloudDevState == nil || cloudDevState != state {
                    cloudDevState = state
                    if (state == OBJC_eCloudDeviceState.CONNECTED || state == OBJC_eCloudDeviceState.INACTIVE) {
                        MALOG("remove offline pop up in case shown")
                        VLGUIManager.shared.visibaleOfflineStatusSignal.send(false)
                        subscribe(speaker: speaker)
                    } else {
                        VLGUIManager.shared.visibaleOfflineStatusSignal.send(true)
                        unsubscribe(speaker: speaker)
                    }
                }
            }
        }
    
    func stopMonitoring(speaker: ISpeaker) {
        unsubscribe(speaker: speaker)
    }
    
    func observerDeviceEvent(deviceId: String) {
        guard let locationIDString = VLModelStore.getLocationId, let locationID = try? Location.ID(json: locationIDString) else {
            MALOG("could not create location")
            return
        }
        MALOG("devieId is \(deviceId)")
        MALOG("locationIDString is \(locationIDString)")
        MALOG("location id is \(locationID)")
        
        guard let store = avEngine.stEngine.environment?.dataLayer.devicesStore(for: locationID) else {
            MALOG("Store Not found!")
            return
        }
        MALOG("store found")
        self.store = store
        store.removeObserver(self)
        self.store?.registerObserver(self) { strongSelf, valueChange in
            MALOG("valueChange \(valueChange)")
            switch valueChange {
            case .devices(.deleted(let delDeviceID), _):
                MALOG("devices event delDeviceID is \(delDeviceID.stringValue)")
                if (delDeviceID.stringValue == deviceId) {
                    VLGUIManager.shared.visibaleOfflineStatusSignal.send(true)
                } else if strongSelf.speakerManager.selectedSpeaker?.stHub.stHubId != "" && delDeviceID.stringValue == strongSelf.speakerManager.selectedSpeaker?.stHub.stHubId {
                    MALOG("deleted device is sthub")
                    AVEngine.shared.avManagers.sthubManager.removeSTHub()
                }
            case .deletingDevice(let deletedDevice, _):
                MALOG("deleting device \(deletedDevice)")
            default:
                return
            }
        }
    }

    func stopObservingDeviceEvent() {
        if store != nil {
            store?.removeObserver(self)
            store = nil
        }
    }
    
    func get(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {

        guard AVEngine.isNeedGetData(speaker: speaker, uri: apiInfo.uri) else {
            MALOG("[OCFProcess][get] Ignore get slaver speaker:\(speaker), \(apiInfo.uri)")
            return Fail(error: OCFError(errorCode: OCFErrorCode.ocfSlaverIgnored.rawValue)).eraseToAnyPublisher()
        }

        MALOG("[OCFProcess][get] speaker:\(speaker), \(apiInfo.uri)")
        return Future<IOCFResponse, OCFError> {[weak self] promise in
            self?.queue.async {
                guard let ocfDevice = speaker.scDevice.getCloudDevice()?.ocfDevice.value else {
                    MALOG("[OCFProcess][get] Error! ocfDevice is nil")
                    promise(.failure(OCFError(errorCode: OCFErrorCode.ocfDeviceNil.rawValue)))
                    return
                }
                let res = ocfDevice.getRemoteAttributes(apiInfo.uri, { attr, optionalUri, result in
                    MALOG("[OCFProcess][get][callback] speaker:\(speaker), uri:\(String(describing: optionalUri)), result:\(result)-\(result.rawValue), attr:\(String(describing: attr?.json()))")
                    guard let self = self else {
                        MALOG("[OCFProcess][get][callback] Error! object released")
                        promise(.failure(OCFError(errorCode: OCFErrorCode.objReleased.rawValue)))
                        return
                    }

                    let response = OCFResponse(speaker: speaker,
                                               apiInfo: apiInfo,
                                               uri: apiInfo.uri,
                                               attr: attr,
                                               result: result)
                    if result == .OK {
                        let ocfProcess = self.getOCFProcess(apiInfo: apiInfo)
                        ocfProcess?.handle(response: response)
                    }
                    promise(.success(response))
                })
                
                if res != .OK {
                    MALOG("[OCFProcess][get] getRemoteAttributes failed for : \(apiInfo.uri)")
                    let error = OCFError(errorCode: OCFErrorCode.remoteAttributeFailed.rawValue)
                    let response = OCFResponse(speaker: speaker,
                                               apiInfo: apiInfo,
                                               uri: apiInfo.uri,
                                               attr: nil,
                                               result: res)
                    let ocfProcess = self?.getOCFProcess(apiInfo: apiInfo)
                    ocfProcess?.failedHandle(response: response, error: error)
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func set(speaker: ISpeaker, apiInfo: IAPIInfo) -> AnyPublisher<IOCFResponse, OCFError> {
        let attr = OCFHelper.convertToAttributes(params: apiInfo.params)
        MALOG("[OCFProcess][set] speaker:\(String(describing: speaker)), \(apiInfo.uri) \nparam:\(apiInfo.params) \nattrs:\(attr.json())")
        return Future<IOCFResponse, OCFError> {[weak self] promise in
            self?.queue.async {
                guard let ocfDevice = speaker.scDevice.getCloudDevice()?.ocfDevice.value else {
                    MALOG("[OCFProcess][set] Error! ocfDevice is nil")
                    return
                }

                let res = ocfDevice.setRemoteAttributes(apiInfo.uri, attr) { (attr, uri, result) in
                    MALOG("[OCFProcess][callback] setRemoteAttributes result for : \(String(describing: uri)) result: \(result)-\(result.rawValue)")
                    guard let _ = self else {
                        MALOG("[OCFProcess][set][callback] Error! object released")
                        promise(.failure(OCFError(errorCode: OCFErrorCode.objReleased.rawValue)))
                        return
                    }
                }

                if res != .OK {
                    MALOG("[OCFProcess] setRemoteAttributes failed for : \(apiInfo.uri) \(res.rawValue)")
                    promise(.failure(OCFError(errorCode: OCFErrorCode.remoteAttributeFailed.rawValue)))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func makeResources(speaker: VLSpeaker) -> [String: VLOcfResource] {
        var resDict: [String: VLOcfResource] = [:]
        
        let bundle = Bundle(for: type(of: self))
        guard let infoDictionary = bundle.infoDictionary, let bundleName = infoDictionary["CFBundleExecutable"] as? String else {
            return resDict
        }
        
        // TODO: This needs to be tested, it's unclear from the docs if this will work this way.
        for (uri, handlerName) in VLOcfConst.resources {
            if let handlerClass = NSClassFromString(bundleName+"."+handlerName),
               let resource = ((handlerClass as? VLOcfResource.Type)?.init(uri: uri)) {
                resource.speaker = speaker
                resDict[uri] = resource
            }
        }
        return resDict
    }
}

// MARK: - Private methods
extension OCFManager {
    func getOCFProcess(uri: String) -> IOCFProcess? {
        return ocfResources[uri]
    }
    
    func getOCFProcess(apiInfo: IAPIInfo) -> IOCFProcess? {
        return getOCFProcess(uri: apiInfo.uri)
    }
    
    private func subscribe(speaker: ISpeaker, uris: [String]?) {
        MALOG("[OCFProcess][notify] subscribe uris:\(String(describing: uris))")
        _ = speaker.scDevice.cloudDeviceSubscribe(uris: uris) { [weak self]

            (representation: OBJC_RCSRepresentation?, optionalUri: String?, result: OBJC_eOCFResult) in
            MALOG("[OCFProcess][notify][callback] deviceID:\(String(describing: speaker.scDevice.getCloudDevice()?.deviceId)),speaker = \(speaker.name), uri:\(String(describing: optionalUri)), result:\(result.rawValue), attr:\(String(describing: representation?.attributes.json()))")
            guard let self = self else { return }
            guard let uri = optionalUri, let attr = representation?.attributes else { return }
            guard result == .OK || result == .RESOURCE_CHANGED else {
                if let spk = self.speakerManager.speaker(cloudDeviceID: speaker.scDevice.getCloudDevice()?.deviceId), result == .DEVICE_NOT_FOUND {
                    MALOG("[OCFProcess][notify][callback] Calling remove(spk) spk model name = \(spk.modelName)")
                    self.speakerManager.remove(spk)
                }
                return
            }

            VLGUIManager.shared.visibaleOfflineStatusSignal.send(false)
            
            guard let spk = self.speakerManager.speaker(cloudDeviceID: speaker.scDevice.getCloudDevice()?.deviceId) else { return }
            
            if let ocfProcess = self.getOCFProcess(uri: uri) {
                let response = OCFResponse(speaker: spk, uri: uri, attr: attr, result: result)
                ocfProcess.handle(response: response)
            } else if let resource = spk.ocfResources[uri] {
                resource.handle(attr: attr)
            } else {
                MALOG("[OCFProcess][notify][callback] No resource to handle it[\(uri)]!!!")
            }
        }
    }
    
    private func subscribe(speaker: ISpeaker) {

        let mainSpeaker: ISpeaker? = AVEngine.shared.avManagers.speakerManager.selectedSpeaker
        if let mainSpeaker = mainSpeaker, mainSpeaker.isEqual(speaker: speaker) == true {
            MALOG("[AVPlugin|Subscribe] for Master speaker!")
            subscribe(speaker: speaker, uris: speaker.scDevice.getCloudDevice()?.resourceUris)
        } else {
            MALOG("[AVPlugin|Subscribe] for Slaver speaker!")
            subscribe(speaker: speaker, uris: AVEngine.necessaryOCFForSlaverSpeaker())
        }

    }

    private func unsubscribe(speaker: ISpeaker) {
        MALOG("[OCFProcess][notify] unsubscribe uris:\(String(describing: speaker.scDevice.getCloudDevice()?.resourceUris))")
        _ = speaker.scDevice.cloudDeviceUnsubscribe(uris: nil)
    }
    
    private func OCFDeviceIsReady(notification: Notification) {
        guard let spk = speakerManager.selectedSpeaker else {
            MALOG("[OCFManager] speaker is null in OCFDeviceIsReady")
            return
        }
        guard let deviceId = notification.userInfo?["deviceId"] as? String,
                deviceId == spk.scDevice.getCloudDevice()?.deviceId else {
            return
        }
        
        MALOG("[OCFManager] OCFDeviceIsReady() deviceID :\(String(describing: deviceId))")
        self.subscribe(speaker: spk)
    }
    
    private func OCFDeviceIsNotReady(notification: Notification) {
        guard let spk = speakerManager.selectedSpeaker else {
            MALOG("[OCFManager] speaker is null in OCFDeviceIsNotReady")
            return
        }
        guard let deviceId = notification.userInfo?["deviceId"] as? String,
                deviceId == spk.scDevice.getCloudDevice()?.deviceId else {
            return
        }
        
        MALOG("[OCFManager] OCFDeviceIsNotReady() deviceID :\(String(describing: deviceId))")
    }
}

extension OCFManager {
    static func ocfResources() -> [String: IOCFProcess] {
        return [
            VLOcfConst.URI_SOUNDMODE: OCFSoundmodeProcess(),
            VLOcfConst.URI_EQ: OCFEQProcess(),
            VLOcfConst.URI_TONE: OCFEQToneProcess(),
            VLOcfConst.URI_EQ_MENU: OCFEQMenuProcess(),
            VLOcfConst.URI_CUSTOM_SETTINGS: OCFCustomSettingsProcess(),
            VLOcfConst.URI_AI_LIGHTINGMODE: OCFLightingModeProcess(),
            VLOcfConst.URI_AI_USBMODE: OCFUSBModeProcess(),
            VLOcfConst.URI_AI_SPEAKER_HEADSET_MODE: OCFSpeakerHeadsetModeProcess(),
            VLOcfConst.URI_AI_SMARTTHINGSHUB: OCFSTHubProcess(),
            VLOcfConst.URI_AI_ALEXA_AISETTING_POPUP: OCFAlexaInitialProcess(),
            VLOcfConst.URI_AI_BIXBY_ON_BOARDING: OCFBixbyOnboardingProcess(),
            VLOcfConst.URI_AI_BIXBY_SETTING: OCFBixbySettingsProcess(),
            VLOcfConst.URI_AI_HIDDENMENU_DOWNLOADABLE_APP: OCFDownloadableAppProcess(),
            VLOcfConst.URI_AI_SES_INFO: OCFSesInfoProcess(),
            VLOcfConst.URI_AI_INFOLINK: OCFInfoLinkProcess(),
            VLOcfConst.URI_OIC_P: OCFOICPProcess(),
            VLOcfConst.URI_AI_VA_SUPPORT: OCFVAProcess(),
            VLOcfConst.URI_AI_GOOGLE_ASSIST: OCFGoogleAssistProcess(),
            VLOcfConst.URI_AI_PASSTHROUGH: OCFPassThroughProcess(),
            VLOcfConst.URI_NETWORKINFO: OCFNetworkStatusProcess(),
            VLOcfConst.URI_AI_ADVANCEDAUDIO: OCFAdvancedAudioProcess(),
            VLOcfConst.URI_AUDIO_PROMPT: OCFAudioPromptProcess(),
            VLOcfConst.URI_DIAL_CONTROLLER_STATUS: OCFDialControllerStatusProcess(),
            VLOcfConst.URI_APD: OCFAutoPowerDownProcess(),
            VLOcfConst.URI_INSTALLATIONTYPE: OCFInstallationTypeProcess(),
            VLOcfConst.URI_FEATURE: OCFFeatureProcess(),
            VLOcfConst.URI_AI_SURROUND_SPEAKER: OCFSurroundSpeakerProcess(),
            VLOcfConst.URI_WIFI_UPDATE: OCFWifiUpdateProcess(),
            VLOcfConst.URI_MEDIA_PLAYBACK: OCFMediaPlaybackProcess(),
            VLOcfConst.URI_MEDIA_TRACK_CONTROL_NEW: OCFMediaTrackControlProcess(),
            VLOcfConst.URI_AUDIO_TRACK_DATA_NEW: OCFAudioTrackDataProcess()
        ]
    }
}
