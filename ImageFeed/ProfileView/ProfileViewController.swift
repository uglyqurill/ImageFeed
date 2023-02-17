import UIKit

final class ProfileViewController: UIViewController {
    var labelName: UILabel = UILabel()
    var labelLogin: UILabel = UILabel()
    var labelDescription: UILabel = UILabel()
    //var exitButton = UIButton()
    var exitButton = UIButton.systemButton(
        with: UIImage(named: "logoutIcon")!,
        target: self,
        action: #selector(Self.didTapLogoutButton)
    )
    var profilePicture: UIImageView = UIImageView()
    private var profileService = ProfileService()
    private let oauth2TokenStorage = OAuth2TokenStorage()
    private var userProfileData: ProfileService.Profile?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        let profileImage = UIImage(named: "userPic")
        let profilePicture = UIImageView(image: profileImage)
        profilePicture.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(profilePicture)
    
        createProfileName(profileName: labelName)
        createLabelLogin(labelLogin: labelLogin)
        createExitButton(exitButton: exitButton)
        createLabelDescription(labelLogin: labelDescription)
        
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
        
        let token = self.oauth2TokenStorage.token ?? "No token"
        
        fetchProfile(token: token)
        
    }
    
    private func fetchProfile (token: String) {
        ProfileService().fetchProfile(token) { result in
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
    
//    private func fetchProfileImageURL (username: String, token: String) {
//        ProfileImageService().fetchProfileImageURL(username: username, token: token) { result in
//            switch result {
//            case .success(let )
//            }
//        }
//    }
    
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
        labelName.text = "Екатерина Новикова"
        labelName.textColor = .white
        labelName.font = UIFont(name: labelName.font.fontName, size: 23) // я не разобрался, как правильно задать шрифт, подскажите пожалуйста)
        labelName.translatesAutoresizingMaskIntoConstraints = false
        //self.labelName = labelName
        view.addSubview(labelName)
    }
    
    func createLabelLogin(labelLogin: UILabel){
        labelLogin.text = "@ekaterina_nov"
        labelLogin.textColor = .gray
        labelLogin.font = UIFont(name: labelLogin.font.fontName, size: 13)
        labelLogin.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelLogin)
    }
    
    func createLabelDescription(labelLogin: UILabel){
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

//extension ProfileViewController {
//    func updateProfileDetails(profile: Profile) {
//
//    }
//}

