//
//  XML+Extension.swift
//  VolumeRemote
//
//  Created by Le Anh Huan on 10/01/2024.
//

import Foundation
class XMLParsing: NSObject, XMLParserDelegate {
    var uic: UIC?
    var currentProperty: String?
    
    func parse(xmlString: String) -> UIC? {
        let parser = XMLParser(data: xmlString.data(using: .utf8)!)
        parser.delegate = self
        parser.parse()
        return uic
    }
    
    func parserDidStartDocument(_ parser: XMLParser) {
        uic = UIC()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentProperty = elementName
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if let currentProperty = currentProperty {
            switch currentProperty {
            case "method":
                uic?.method = string
            case "version":
                uic?.version = string
            case "speakerip":
                uic?.speakerip = string
            case "user_identifier":
                uic?.userIdentifier = string
            case "result":
                uic?.response?.result = string
            case "volume":
                uic?.response?.volume = Int(string)
            case "mute":
                uic?.response?.mute = string == "off" ? false : true
            default:
                break
            }
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "response" {
            uic?.response = Response(result: uic?.response?.result, volume: uic?.response?.volume, mute: uic?.response?.mute)
        }
        currentProperty = nil
    }
}

struct UIC {
    var method: String?
    var version: String?
    var speakerip: String?
    var userIdentifier: String?
    var response: Response?
}

struct Response {
    var result: String?
    var volume: Int?
    var mute: Bool?
}
