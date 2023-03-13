import UIKit
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
        
        let profileImage = UIImage(named: "userPic")
        profilePicture.image = profileImage
        profilePicture.translatesAutoresizingMaskIntoConstraints = false
        
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = 35
        
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
        labelName.text = "Вы вышли из профиля"
        labelLogin.removeFromSuperview()
        labelDescription.removeFromSuperview()
        labelLogin.text = "unknown"
        labelDescription.text = "unknown"
    }
}

extension ProfileViewController {
    
    func createProfileName(profileName: UILabel){
        labelName.text = "Username"
        labelName.textColor = .white
        labelName.font = UIFont(name: labelName.font.fontName, size: 23) // я не разобрался, как правильно задать шрифт, подскажите пожалуйста)
        labelName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelName)
    }
    
    func createLabelLogin(labelLogin: UILabel){
        labelLogin.text = "@userlogin"
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


