//
//  Presenter.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation

protocol PresenterProtocol: AnyObject {
    
    func adjustVolume()
    
}

class Presenter: PresenterProtocol {
    private weak var view: ViewProtocol?
    private var router: RouterProtocol?
    private var interactor: InteractorProtocol?
    
    init(view: ViewProtocol?, router: RouterProtocol?, interactor: InteractorProtocol?) {
        self.view = view
        self.router = router
        self.interactor = interactor
    }
    
    func adjustVolume() {
        in
    }
    
}
