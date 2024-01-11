//
//  Builder.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation
import UIKit

protocol BuilderProtocol: AnyObject {
    func build() -> ViewProtocol?
}

class Builder: BuilderProtocol {
    func build() -> ViewProtocol? {
        
        let router = Router()
        var view = ViewController()
        
        let initSpeaker = Speaker()
        let speakerStore = SpeakerStore(speaker: initSpeaker)
        let speakerRepository = SpeakerRepository(speakerStore: speakerStore)
        
        let interactor = Interactor(speakerRepository: speakerRepository, speaker: initSpeaker)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        view = storyboard.instantiateViewController(identifier: "ViewController")
        
        let presenter = Presenter(view: view, router: router, interactor: interactor)
        
        view.presenter = presenter
//        interactor.presenter = presenter
        router.view = view
        
        return view
        
    }
    
    
}
