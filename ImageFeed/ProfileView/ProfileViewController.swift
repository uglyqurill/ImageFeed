import UIKit
import WebKit
import Kingfisher


protocol ProfileViewControllerProtocol: AnyObject {
    //var presenter: ProfileViewPresenterProtocol? { get set }
    func updateProfile()
    func updateAvatar()
    func configureProfile()
}

final class ProfileViewController: UIViewController & ProfileViewControllerProtocol {
    var labelName: UILabel = UILabel()
    var labelLogin: UILabel = UILabel()
    var labelDescription: UILabel = UILabel()
    var exitButton = UIButton.systemButton(
        with: UIImage(named: "logoutIcon")!,
        target: self,
        action: #selector(Self.didTapLogoutButton)
    )
    
    private var profilePicture = UIImageView()
    private var profileService = ProfileService.shared
    private var profileImageService = ProfileImageService()
    private let tokenStorage = SwiftKeychainWrapper()
    private var oAuth2Service = OAuth2Service()
    
    lazy var presenter: ProfileViewPresenterProtocol = {
        ProfileViewPresenter(viewController: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .ypBlack
        
        let profileImage = UIImage(named: "userPic")
        profilePicture.image = profileImage
        profilePicture.translatesAutoresizingMaskIntoConstraints = false
        
        profilePicture.layer.cornerRadius = 35
        profilePicture.layer.masksToBounds = true
        
        view.addSubview(profilePicture)
        
        configureProfile()
        
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
        
        //let token = profileImageService.tokenStorage.getBearerToken() ?? "nil"
        //fetchProfile(token: token)
        updateProfile()
        updateAvatar()
        
    }
    
    func configureProfile() {
        createProfileName(profileName: labelName)
        createLabelLogin(labelLogin: labelLogin)
        createExitButton(exitButton: exitButton)
        createLabelDescription(labelDescription: labelDescription)
    }
    
    internal func updateProfile() {
        guard let profile = presenter.getProfile() else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.labelName.text = profile.name
            self.labelLogin.text = profile.loginName
            self.labelDescription.text = profile.bio
        }
    }

    
    internal func updateAvatar() { // 2
        guard let url = presenter.getAvatar() else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.profilePicture.kf.indicatorType = .activity
            self.profilePicture.kf.setImage(with: url)

        }
        
    }
    
    
    @objc
    
    func didTapLogoutButton() {
        
        let alert = UIAlertController(title: "Пока, пока!",
                                      message: "Уверены что хотите выйти?",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { [weak self] _ in
            self?.logout()
        }))
        
        alert.addAction(UIAlertAction(title: "Нет", style: .default, handler: { _ in
            //nothing
        }))
        present(alert, animated: true)
    }
        
}

extension ProfileViewController {
    
    private func logout() { // 3
        presenter.logout()
    }
    
    private func clearStorage() {
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
    
    private func clearToken() {
        tokenStorage.deleteBearerToken()
    }
    
    private func switchToSplashScreen() {
        guard let window = UIApplication.shared.windows.first else { fatalError("Fatal Error") }
        let authViewController = UIStoryboard(name: "Main", bundle: .main)
            .instantiateViewController(withIdentifier: "AuthViewController")
        window.rootViewController = authViewController
    }
}

extension ProfileViewController {
    
    
    
    private func createProfileName(profileName: UILabel){
        labelName.text = "User Name"
        labelName.textColor = .white
        labelName.font = UIFont.boldSystemFont(ofSize: 23)
        labelName.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelName)
    }
    
    private func createLabelLogin(labelLogin: UILabel){
        labelLogin.text = "@user"
        labelLogin.textColor = .gray
        labelLogin.font = UIFont.systemFont(ofSize: 13)
        labelLogin.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelLogin)
    }
    
    private func createLabelDescription(labelDescription: UILabel){
        labelDescription.text = "Hello, world!"
        labelDescription.textColor = .white
        labelDescription.font = UIFont.systemFont(ofSize: 13)
        labelDescription.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelDescription)
    }
    
    private func createExitButton(exitButton: UIButton){
        exitButton.tintColor = .red
        exitButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(exitButton)
    }
}

extension UIColor {
    static let ypBlack = UIColor(named: "ypBlack")!
}

