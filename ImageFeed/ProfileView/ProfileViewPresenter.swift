import Foundation
import WebKit

protocol ProfileViewPresenterProtocol: AnyObject {
    //var view: ProfileViewControllerProtocol? { get set }
    func viewDidLoad()
    func getProfile() -> Profile?
    func getAvatar() -> URL?
    func logout()
}

final class ProfileViewPresenter: ProfileViewPresenterProtocol {
    // MARK: - Properties
    weak var view: ProfileViewControllerProtocol?
    private let queue = DispatchQueue(label: "profile.vc.queue", qos: .unspecified)
    private let tokenStorage = SwiftKeychainWrapper()
    private var profileService: ProfileService
    private var profileImageService = ProfileImageService()
    
    init(
        profileService: ProfileService = .shared,
        viewController: ProfileViewControllerProtocol
    ) {
        self.profileService = profileService
    }
    
    // MARK: - Methods
    func viewDidLoad() {
        view?.configureProfile()
        //tokenStorage.getBearerToken()
    }
    
    func getProfile() -> Profile? {
        let profile = profileService.profile
        return profile
        
    }
    
    func getAvatar() -> URL? {
        let profileImageURL = ProfileImageService.shared.avatarURL ?? ""
        let url = URL(string: profileImageURL)
        return url
    }

    func logout() { // 3
        clearStorage()
        clearToken()
        switchToSplashScreen()
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
