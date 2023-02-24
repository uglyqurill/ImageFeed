//
//  SwiftKeychainWrapper .swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 24.02.2023.
//

import Foundation
import SwiftKeychainWrapper

final class SwiftKeychainWrapper {

    func setAuthToken(token: String?){
        guard let token = token else { return }
        let isSuccess = KeychainWrapper.standard.set(token, forKey: "Auth token")
        guard isSuccess else {
            return
        }
    }

    func getAuthToken() -> String? {
        return KeychainWrapper.standard.string(forKey: "Auth token")
    }

    func setBearerToken(token: String?){
        guard let token = token else { return }
        let isSuccess = KeychainWrapper.standard.set(token, forKey: "Bearer token")
        guard isSuccess else {
            return
        }
    }

    func getBearerToken() -> String? {
        return KeychainWrapper.standard.string(forKey: "Bearer token")
    }
}
