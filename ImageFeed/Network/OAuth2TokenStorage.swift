//
//  OAuth2TokenStorage.swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 08.02.2023.
//

//import Foundation
//
//final class OAuth2TokenStorage {
//    private let userDefaults = UserDefaults.standard
//    private enum Keys: String, CodingKey {
//        case bearerToken
//    }
//    
//    var token: String? {
//        get {
//            return userDefaults.string(forKey: Keys.bearerToken.rawValue)
//        }
//        set {
//            userDefaults.set(newValue, forKey: Keys.bearerToken.rawValue)
//            print(userDefaults.string(forKey: Keys.bearerToken.rawValue))
//        }
//    }
//}
