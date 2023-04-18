import Foundation
import SwiftKeychainWrapper

final class OAuth2TokenStorage {
    private let keyChain = KeychainWrapper.standard
    private let tokenKey = "token"

    var token: String? {
        get {
            keyChain.string(forKey: tokenKey)
        }
        set {
            if let token = newValue {
                keyChain.set(token, forKey: tokenKey)
            } else {
                keyChain.removeObject(forKey: tokenKey)
            }
        }
    }
}
