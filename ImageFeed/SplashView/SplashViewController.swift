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
    
    private let loadingScreenImage = UIImageView()
    
    override func viewDidLoad() {

        view.backgroundColor = UIColor(named: "YP Black")
        createLoadingScreenImage()

        NSLayoutConstraint.activate([
            loadingScreenImage.widthAnchor.constraint(equalToConstant: 75),
            loadingScreenImage.heightAnchor.constraint(equalToConstant: 78),
            loadingScreenImage.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            loadingScreenImage.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor)
            ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.profileImageService.tokenStorage.getBearerToken() != nil &&
            self.profileImageService.tokenStorage.getAuthToken() != nil {

            let token = profileImageService.tokenStorage.getBearerToken() ?? "nil"
            //UIBlockingProgressHUD.show()
            fetchProfile(token: token)
        } else {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let storyboard = UIStoryboard(name: "Main", bundle: .main)
                guard let authViewController = storyboard.instantiateViewController(withIdentifier: "AuthViewController") as? AuthViewController else { return }
                authViewController.delegate = self
                authViewController.modalPresentationStyle = .fullScreen
                self.present(authViewController, animated: true)
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
    
    private func fetchOAuthToken(_ code: String) {
        oauth2Service.fetchOAuthToken(code) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let token):
                self.fetchProfile(token: token)
                UIBlockingProgressHUD.dismiss()
            case .failure:
                // TODO [Sprint 11]
                break
            }
        }
    }
    
    private func fetchProfile(token: String) {
        profileService.fetchProfile(token) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let profile): //
                    ProfileImageService.shared.fetchProfileImageURL(profile.username) { result in
                        switch result {
                        case .success(let avatarURL):
                            DispatchQueue.main.async {
                                self.profileImageService.setAvatarUrlString(avatarUrl: avatarURL)
                            }
                        case .failure:
                            return
                        }
                    }
                    UIBlockingProgressHUD.dismiss()
                    self.switchToTabBarController()
                case .failure:
                    UIBlockingProgressHUD.dismiss()
                    break
                }
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
    
    func createLoadingScreenImage() {
        self.loadingScreenImage.translatesAutoresizingMaskIntoConstraints = false
        self.loadingScreenImage.image = UIImage(named: "auth_screen_logo")
        view.addSubview(self.loadingScreenImage)
    }
}


