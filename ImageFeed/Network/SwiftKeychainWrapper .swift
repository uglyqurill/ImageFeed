import Foundation
import SwiftKeychainWrapper

final class SwiftKeychainWrapper {

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
    
    func deleteBearerToken(){
        KeychainWrapper.standard.removeObject(forKey: "Bearer token")
    }
}
