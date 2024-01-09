//
//  Interactor.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation

protocol InteractorProtocol: AnyObject {
    func adjustVolumeRequest()
}

class Interactor: InteractorProtocol {
    weak var presenter: PresenterProtocol?
    private var entity: Entity?
    
    func adjustVolumeRequest() {
        <#code#>
    }
}
