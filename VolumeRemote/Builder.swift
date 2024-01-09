//
//  Builder.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation
import UIKit

//typealias EntryPoint = ViewProtocol

protocol BuilderProtocol: AnyObject {
    func build() -> ViewProtocol?
}

class Builder: BuilderProtocol {
    func build() -> ViewProtocol? {
        
        var router = Router()
        var view = ViewController()
        var interactor = Interactor()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        view = storyboard.instantiateViewController(identifier: "ViewController")
        
        var presenter = Presenter(view: view, router: router, interactor: interactor)
        
        view.presenter = presenter
        interactor.presenter = presenter
        router.view = view
        
        return view
        
    }
    
    
}
