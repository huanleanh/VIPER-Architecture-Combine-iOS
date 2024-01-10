//
//  Presenter.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

//presenter sink interactor to update UI

import Foundation

protocol PresenterProtocol: AnyObject {
    var dataForView: Speaker {get}
    func adjustVolume(volumeValue: Int)
    func updateMuteState(isMute: Bool)
    func updateConnection(type: ConnectionType)
    
}

class Presenter: PresenterProtocol {
    var dataForView: Speaker {return interactor?.speakerEntity ?? Speaker()}
    private weak var view: ViewProtocol?
    private var router: RouterProtocol?
    private var interactor: InteractorProtocol?
    
    init(view: ViewProtocol?, router: RouterProtocol?, interactor: InteractorProtocol?) {
        self.view = view
        self.router = router
        self.interactor = interactor
        print(dataForView)
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
    
//    func updateSoundBar(_ switchButton: UISwitch) {
//       // Lấy thông tin isOn từ switch button
//       let isOn = switchButton.isOn
//
//       // Cập nhật trạng thái của object SoundBar
//       soundBar.isOn = isOn
//
//       // Gửi object SoundBar đến server
//       interactor.sendSoundBar(soundBar)
//     }
//   }
    
}
