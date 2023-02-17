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
    
    private(set) var avatarURL: String?
    
    func fetchProfileImageURL(_ username: String, completion: @escaping (Result<String, Error>) -> Void) {
        
        assert(Thread.isMainThread)
        if lastToken == token { return }
        task?.cancel()
        lastToken = token
        
        guard let token = token else {
            return
        }
        
        let request = requestProfileImage(username: username, token: token)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { return }
            guard let data = data else { return }
            
            do {
                let json = try JSONDecoder().decode(UserResult.self, from: data)
                guard let userResultURL = json.profileImage.small else { return }
                self.avatarURL = userResultURL
                completion(.success(userResultURL))
                NotificationCenter.default                                     // 1
                    .post(                                                     // 2
                        name: ProfileImageService.DidChangeNotification,       // 3
                        object: self,                                          // 4
                        userInfo: ["URL": self.avatarURL])                    // передаём URL аватарки
            } catch let error {
                completion(.failure(error))
            }
            
            self.task = nil
            if error != nil {
                self.lastToken = nil
                self.lastUsername = nil
            }
        }
        self.task = task
        task.resume()
    }

    
//    func fetchProfileImageURL(username: String, token: String, _ completion: @escaping (Result<String, Error>) -> Void) {
//        assert(Thread.isMainThread)
//
//
//        if lastToken == token { return }
//        task?.cancel()
//        lastToken = token
//
//        if lastUsername == username { return }
//        task?.cancel()
//        lastUsername = username
//
//        let request = requestProfileImage(username: username, token: token)
//
//        let task = urlSession.dataTask(with: request) { data, response, error in
//            DispatchQueue.main.async { return }
//            guard let data = data else { return }
//
//            do {
//                let json = try JSONDecoder().decode(UserResult.self, from: data)
//                guard let userResultURL = json.profileImage.small else { return }
//                self.avatarURL = userResultURL
//                completion(.success(userResultURL))
//            } catch let error {
//                completion(.failure(error))
//            }
//
//            self.task = nil
//            if error != nil {
//                self.lastToken = nil
//                self.lastUsername = nil
//            }
//        }
//        self.task = task
//        task.resume()
//    }
    
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
          avatarURL = avatarUrl
      }
}
