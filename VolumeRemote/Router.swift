//
//  Router.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 09/01/2024.
//

import Foundation
import UIKit



protocol RouterProtocol: AnyObject {
    var view: ViewProtocol? {get set}

}

class Router: RouterProtocol {
    var view: ViewProtocol?
}

