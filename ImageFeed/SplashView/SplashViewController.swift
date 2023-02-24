import UIKit
import Foundation
import ProgressHUD

final class SplashViewController: UIViewController {
    private let ShowAuthenticationScreenSegueIdentifier = "ShowAuthenticationScreen"
    private let oauth2Service = OAuth2Service()
    private let tokenStorage = SwiftKeychainWrapper()
    private let profileService = ProfileService.shared
    private let profileImageService = ProfileImageService.shared
    
    private let queue = DispatchQueue(label: "splash.vc.queue", qos: .unspecified)
    let lastErroCode = Int()
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        if let token = tokenStorage.getAuthToken() {
//            fetchProfile(token: token)
//        } else {
//            performSegue(withIdentifier: ShowAuthenticationScreenSegueIdentifier, sender: nil)
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.profileImageService.tokenStorage.getBearerToken() != nil &&
            self.profileImageService.tokenStorage.getAuthToken() != nil {

            let token = profileImageService.tokenStorage.getBearerToken() ?? "nil"
            UIBlockingProgressHUD.show()
            fetchProfile(token: token)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performSegue(withIdentifier: self.ShowAuthenticationScreenSegueIdentifier, sender: nil)
            }
        }
    }
    
    private func switchToTabBarController() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Invalid Configuration") }
        
        let tabBarController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "TabBarViewController")
           
        window.rootViewController = tabBarController
    }
}

extension SplashViewController {
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == ShowAuthenticationScreenSegueIdentifier {
            guard
                let navigationController = segue.destination as? UINavigationController,
                let viewController = navigationController.viewControllers[0] as? AuthViewController
            else { fatalError("Failed to prepare for \(ShowAuthenticationScreenSegueIdentifier)") }
            
            viewController.delegate = self
        } else {
            super.prepare(for: segue, sender: sender)
        }
    }
}

extension SplashViewController: AuthViewControllerDelegate {
    func authViewController(_ vc: AuthViewController, didAuthenticateWithCode code: String) {
        
        UIBlockingProgressHUD.show()
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.fetchOAuthToken(code)
        }
    }
    
    private func fetchOAuthToken (_ code: String) {
        self.oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let bearerToken):
                self.profileImageService.tokenStorage.setBearerToken(token: bearerToken)
                DispatchQueue.main.async {
                    self.fetchProfile(token: bearerToken)
                }
            case .failure(let error):
                //self.showAlert(error: error)
                return
            }
        }
    }
    
    private func fetchProfile (token: String) {
        profileService.fetchProfile(token) {[weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let profile):
                self.queue.sync {
                    self.profileService.setProfile(profile: profile)
                }
                self.queue.sync {
                    ProfileImageService.shared.fetchProfileImageURL(
                        self.profileService.profile?.username ?? "NIL") { result in
                            switch result {
                            case .success(let avatarURL):
                                DispatchQueue.main.async {
                                    self.profileImageService.setAvatarUrlString(avatarUrl: avatarURL)
                                }
                            case .failure:
                                
                                // TODO: нужно добавить алерт для неудачной загрузки картинки профиля и передать её в экран профиля
                                return
                            }
                        }
                }
                self.switchToTabBarController()
                return
                
            case .failure(let errorCode):
                //self.showAlert(error: errorCode)
                return
            }
        }
    }
}

extension SplashViewController {
    private func showAlert() {
        let alert = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось войти в систему",
            preferredStyle: .alert)
        
        let action = UIAlertAction(
            title: "Ок",
            style: .cancel,
            handler: { _ in
                alert.dismiss(animated: true, completion: nil)
            })
        
        alert.addAction(action)
        self.present(alert, animated: true, completion: nil)
    }
}


