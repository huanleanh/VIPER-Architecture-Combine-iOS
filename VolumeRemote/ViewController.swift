//
//  ViewController.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import UIKit
import Combine


let INIT_VOLUME = 5

protocol ViewProtocol: AnyObject {
    
}

class ViewController: UIViewController {

    @IBOutlet weak var modeButton: UISwitch!
    
    @IBOutlet weak var volDownButton: UIButton!
    
    @IBOutlet weak var volUpButton: UIButton!
    
    @IBOutlet weak var muteButton: UIButton!
    
    @IBOutlet weak var volumeInfoText: UILabel!
    
    var volumeValue = 5
    
    var isMuted = false
    
    var presenter: PresenterProtocol?
    var connectionMode = true
    
//    var connectionMode: PassthroughSubject<Bool, Never>?
    
    
    @IBAction func modeHasChanged(_ sender: Any) {
//        modeButton.isOn = !modeButton.isOn
        connectionMode = modeButton.isOn
        
        print("Connecttion mode: \(connectionMode ? "D2S" : "D2D")")
    }
    
    @IBAction func volDownButtonClicked(_ sender: Any) {
//        presenter.
        adjustVolume(isAdd: false)
    }
    
    @IBAction func volUpButtonClicked(_ sender: Any) {
        adjustVolume(isAdd: true)
    }
    
    @IBAction func mutButtonClicked(_ sender: Any) {
        isMuted = !isMuted
        print("Is mute: \(isMuted)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.setup()
    }
    
    func adjustVolume(isAdd: Bool) {
        volumeValue += isAdd ? 1 : -1
        print("New volume value is: \(volumeValue)")
        volumeInfoText.text = String(volumeValue)
//        presenter.
    }
    
    func setup() {
        func setupUI() {
            volumeInfoText.text = String(INIT_VOLUME)
        }
        
        func setupAction() {
            
        }
        
        setupUI()
        setupAction()
    }
}

extension ViewController: ViewProtocol {
    
}

