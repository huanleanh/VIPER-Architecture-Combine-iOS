//
//  Presenter.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

//presenter sink interactor to update UI

import Foundation
import Combine

protocol PresenterProtocol: AnyObject {
    var presenterPublisher: PassthroughSubject<VolumeEvent, Never> { get }
    var dataForView: Speaker {get}

    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
    
}

class Presenter: PresenterProtocol {
    var dataForView: Speaker {
//        print("Cbi lay thong tin tu interactor ", interactor?.getUseCase().getSpeaker())
        return interactor?.getUseCase().getSpeaker() ?? Speaker()
    }
    private(set) weak var view: ViewProtocol?
    private(set) var router: RouterProtocol?
    private(set) var interactor: InteractorProtocol?
    
    private(set) var presenterPublisher = PassthroughSubject<VolumeEvent, Never>()
    private var bags = Set<AnyCancellable>()
    
    init(view: ViewProtocol?, router: RouterProtocol?, interactor: InteractorProtocol?) {
        self.view = view
        self.router = router
        self.interactor = interactor
        
        interactor?.interactorPublisher
            .sink(receiveValue: { [weak self] event in
                self?.presenterPublisher.send(event)
            })
            .store(in: &bags)
//        print(dataForView)
    }
    
    func adjustVolume(volumeValue: Int) {
        interactor?.makeAdjustVolumeRequest(volumeValue: volumeValue)
    }
    
    func updateMuteState(isMute: Bool) {
        interactor?.makeUpdateMuteStateRequest(isMute: isMute)
    }
    
    func updateConnection(type: ConnectionType) {
        interactor?.updateConnection(type: type)
    }
    
}
