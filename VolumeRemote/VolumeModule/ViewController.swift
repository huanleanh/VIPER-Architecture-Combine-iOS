//
//  ViewController.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import UIKit
import Combine


let INIT_VOLUME = 5
let MIN_VOLUME = 0
let MAX_VOLUME = 10

protocol ViewProtocol: AnyObject {
    var presenter: PresenterProtocol? {get set}
}

class ViewController: UIViewController {
    
    @IBOutlet var rootView: UIView!
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var loadingView: UIView!
    
    @IBOutlet weak var connectionModeButton: UISwitch!
    
    @IBOutlet weak var volDownButton: UIButton!
    
    @IBOutlet weak var volUpButton: UIButton!
    
    @IBOutlet weak var muteButton: UIButton!
    
    @IBOutlet weak var volumeInfoText: UILabel!
    
    @IBOutlet weak var muteStateImage: UIImageView!
    
    var volumeValue = 5 {
        didSet {
            volumeInfoText.text = String(volumeValue)
        }
    }
    
    var isMuted = false {
        didSet {
            muteStateImage.image = isMuted ? UIImage(named: "mute.png") : UIImage(named: "unmute.png")
        }
    }
    
    var presenter: PresenterProtocol?
    
    var bags = Set<AnyCancellable>()
    
    @IBAction func modeHasChanged(_ sender: Any) {
        print("User changed connecttion mode from \(connectionModeButton.isOn ? "D2D" : "D2S") to \(connectionModeButton.isOn ? "D2S" : "D2D")")
        presenter?.updateConnection(type: connectionModeButton.isOn ? ConnectionType.D2S : ConnectionType.D2D)
    }
    
    @IBAction func volDownButtonClicked(_ sender: Any) {
        makeLoadingView(isShow: true)
        print("User adjusted volume down")
        adjustVolume(isAdd: false)
    }
    
    @IBAction func volUpButtonClicked(_ sender: Any) {
        makeLoadingView(isShow: true)
        print("User adjusted volume up")
        adjustVolume(isAdd: true)
    }
    
    @IBAction func muteButtonClicked(_ sender: Any) {
        makeLoadingView(isShow: true)
//        isMuted = !isMuted
        print("User tapped on Mute button, is mute: \(isMuted)")
        presenter?.updateMuteState(isMute: !isMuted)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
    }
    
    func makeLoadingView(isShow: Bool) {
        if isShow {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        
        loadingView.isHidden = !isShow
    }
    
    func adjustVolume(isAdd: Bool) {
        if isAdd {
            if self.volumeValue < MAX_VOLUME {
//                self.volumeValue += 1
                presenter?.adjustVolume(volumeValue: volumeValue + 1)
            } else {
                return
            }
        } else {
            if self.volumeValue > MIN_VOLUME {
//                self.volumeValue -= 1
                presenter?.adjustVolume(volumeValue: volumeValue - 1)
            } else {
                return
            }
        }
        
    }
    
    func updateVolumeText() {
        print("Get data for view, speaker's volume: \(String(describing: presenter?.dataForView.volume))")
        volumeValue = (presenter?.dataForView.volume)!
    }
    
    func updateMuteState() {
        print("Get data for view, speaker is muted: \(String(describing: presenter?.dataForView.isMute))")
        isMuted = (presenter?.dataForView.isMute)!
    }
    
    func setup() {
        func setupUI() {
            rootView.bringSubviewToFront(loadingView)
            loadingView.alpha = 0.5
            loadingView.isHidden = true
            volumeInfoText.text = String(INIT_VOLUME)
            
        }
        
        func setupAction() {
            
            presenter?.presenterPublisher
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { [weak self] event in
                    switch event {
                    case .muteStateHasUpdated: 
                        self?.makeLoadingView(isShow: false)
                        self?.updateMuteState()
                    case .volumeHasUpdated:
                        self?.makeLoadingView(isShow: false)
                        self?.updateVolumeText()
                    }
                })
                .store(in: &bags)
        }
        
        setupUI()
        setupAction()
    }
}

extension ViewController: ViewProtocol {
    
}

