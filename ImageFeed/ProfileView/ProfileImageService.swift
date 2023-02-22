import UIKit
import Foundation

final class ProfileImageService {
    
    static let DidChangeNotification = Notification.Name(rawValue: "ProfileImageProviderDidChange")
    private let urlSession = URLSession.shared
    static let shared = ProfileImageService()
    private var task: URLSessionTask?
    private var lastToken: String?
    private var lastUsername: String?
    private let token = OAuth2TokenStorage().token
    var tokenStorage = OAuth2TokenStorage()
    
    private(set) var avatarURL: String?
    private var userResultURL: String? = nil
    
    func fetchProfileImageURL(_ username: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        assert(Thread.isMainThread)
        if lastToken == token { return }
        task?.cancel()
        lastToken = token
        
        guard let token = token else {
            return
        }
        
        let request = requestProfileImage(username: username, token: token)
        
        let task = urlSession.objectTask(for: request) { (result: Result<UserResult, Error>) in
                    DispatchQueue.main.async { return }
                    switch result {
                    case .success(let json):
                        DispatchQueue.main.async {
                            self.userResultURL = json.profileImage.small
                            completion(.success(json.profileImage.small ?? "nil"))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                    
                    self.task = nil
                }
        self.task = task
        task.resume()
    }

    
    struct UserResult: Codable {
        let profileImage: ImageSize
        
        enum CodingKeys: String, CodingKey {
            case profileImage = "profile_image"
        }
    }
    
    struct ImageSize: Codable {
        let small: String?
        
        enum CodingKeys: String, CodingKey {
            case small = "small"
        }
    }
    
}

extension ProfileImageService {
    func requestProfileImage(username: String, token: String) -> URLRequest {
        
        let unsplashGetProfileImageURLString = defaultBaseURLString + "users/" + username
        
        guard let url = URL(string: unsplashGetProfileImageURLString)
        else { fatalError("Failed to create URL")}
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func setAvatarUrlString(avatarUrl: String) {
        self.avatarURL = avatarUrl
    }
}
