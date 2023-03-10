import UIKit
import WebKit
import Kingfisher
import Foundation


final class ProfileViewController: UIViewController {
    var labelName: UILabel = UILabel()
    var labelLogin: UILabel = UILabel()
    var labelDescription: UILabel = UILabel()
    var exitButton = UIButton.systemButton(
        with: UIImage(named: "logoutIcon")!,
        target: self,
        action: #selector(Self.didTapLogoutButton)
    )
    
    var profilePicture = UIImageView()
    private var profileService = ProfileService()
    private var profileImageService = ProfileImageService()
    private let swiftKeychainWrapper = SwiftKeychainWrapper()
    private var userProfileData: ProfileService.Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        let profileImage = UIImage(named: "userPic")
        profilePicture.image = profileImage
        profilePicture.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(profilePicture)
        
        createProfileName(profileName: labelName)
        createLabelLogin(labelLogin: labelLogin)
        createExitButton(exitButton: exitButton)
        createLabelDescription(labelDescription: labelDescription)
        
        NSLayoutConstraint.activate([
            profilePicture.widthAnchor.constraint(equalToConstant: 70),
            profilePicture.heightAnchor.constraint(equalToConstant: 70),
            profilePicture.topAnchor.constraint(equalTo: view.topAnchor, constant: 76),
            profilePicture.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            labelName.topAnchor.constraint(equalTo: profilePicture.bottomAnchor, constant: 8),
            labelName.leadingAnchor.constraint(equalTo: profilePicture.leadingAnchor),
            
            labelLogin.topAnchor.constraint(equalTo: labelName.bottomAnchor, constant: 8),
            labelLogin.leadingAnchor.constraint(equalTo: profilePicture.leadingAnchor),
            
            labelDescription.topAnchor.constraint(equalTo: labelLogin.bottomAnchor, constant: 8),
            labelDescription.leadingAnchor.constraint(equalTo: profilePicture.leadingAnchor),
            
            exitButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
            exitButton.centerYAnchor.constraint(equalTo: profilePicture.centerYAnchor)
        ])
        
        let token = profileImageService.tokenStorage.getBearerToken() ?? "nil"
        
        fetchProfile(token: token)
        
        updateAvatar()
        
    }
    
    private func fetchProfile (token: String) {
        DispatchQueue.main.async {
            self.profileService.fetchProfile(token) { result in
                switch result {
                case .success (let profile):
                    self.userProfileData = profile
                    self.labelName.text = profile.name
                    self.labelLogin.text = profile.loginName
                    self.labelDescription.text = profile.bio
                    return
                case .failure(let error):
                    print("❌\(error)")
                    return
                    
                }
            }
        }
    }
    
    private func updateAvatar() {
        DispatchQueue.main.async {
            guard
                let profileImageURL = ProfileImageService.shared.avatarURL,
                let url = URL(string: profileImageURL)
            else { return }
            
            let processor = RoundCornerImageProcessor(cornerRadius: 35,backgroundColor: .clear)
            
            self.profilePicture.kf.indicatorType = .activity
            self.profilePicture.kf.setImage(with: url)
        }
        
    }
    
    
    @objc
    
    func didTapLogoutButton() {
        
        let alert = UIAlertController(title: "Logout",
                                      message: "Are you sure you want to logout?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
            //self?.logout()
            self?.logout()
        }))
        
        alert.addAction(UIAlertAction(title: "Нет", style: .default, handler: { _ in
            //nothing
        }))
        present(alert, animated: true)
    }
        
}

extension ProfileViewController {
    
    private func logout() {
        clearStorage()
        switchToSplashScreen()
    }
    
    func clearStorage() {
        // Очищаем все куки из хранилища.
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        // Запрашиваем все данные из локального хранилища.
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
           // Массив полученных записей удаляем из хранилища.
           records.forEach { record in
              WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
           }
        }
    }
    
    func switchToSplashScreen() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Fatal Error") }
        let authViewController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "AuthViewController")
        window.rootViewController = authViewController
    }
}

extension ProfileViewController {
    
    func createProfileName(profileName: UILabel){
        labelName.text = "User Name"
        labelName.textColor = .white
        labelName.font = UIFont(name: labelName.font.fontName, size: 23) // я не разобрался, как правильно задать шрифт, подскажите пожалуйста)
        labelName.translatesAutoresizingMaskIntoConstraints = false
        //self.labelName = labelName
        view.addSubview(labelName)
    }
    
    func createLabelLogin(labelLogin: UILabel){
        labelLogin.text = "@user"
        labelLogin.textColor = .gray
        labelLogin.font = UIFont(name: labelLogin.font.fontName, size: 13)
        labelLogin.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelLogin)
    }
    
    func createLabelDescription(labelDescription: UILabel){
        labelDescription.text = "Hello, world!"
        labelDescription.textColor = .white
        labelDescription.font = UIFont(name: labelDescription.font.fontName, size: 13)
        labelDescription.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelDescription)
    }
    
    func createExitButton(exitButton: UIButton){
        exitButton.tintColor = .red
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exitButton)
    }
}

extension UIColor {
    static let ypBlack = UIColor(named: "ypBlack")!
}

