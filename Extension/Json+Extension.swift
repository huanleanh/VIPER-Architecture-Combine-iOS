////
////  Json+Extension.swift
////  VolumeRemote
////
////  Created by Le Anh Huan on 10/01/2024.
////
//
//import Foundation
//
//// Extension cho struct APIInfo
//class Json: JSONDecoder, JSONEncoder {
//    
//    func makeAttribute(volume: Int?, isMute: Bool?) -> [String: Any] {
//        var attributes: [String: Any] = [:]
//        
//        if let volume = volume {
//            attributes["volume"] = volume
//        }
//        
//        if let isMute = isMute {
//            attributes["mute"] = isMute
//        }
//        
//        return attributes
//    }
//    
//    func parseResponse(json: Data) -> (volume: Int, isMute: Bool)? {
//        let decoder = JSONDecoder()
//        
//        do {
//            let response = try decoder.decode(APIInfo.self, from: json)
//            
//            return (response.params["volume"] as? Int, response.params["isMute"] as? Bool) as? (volume: Int, isMute: Bool)
//        } catch {
//            
//            print("Lỗi parse JSON: \(error)")
//            return nil
//        }
//    }
//}
