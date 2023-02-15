import Foundation
import UIKit

final class ProfileService {
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    static let shared = ProfileService()
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if lastToken == token { return }
        task?.cancel()
        lastToken = token
        
        let request = requestUser(token: token)
        
        let task = urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard let data = data else { return }
                
                do {
                    let json = try JSONDecoder().decode(ProfileResult.self, from: data)
                    let profileResult = ProfileResult(
                        username: json.username,
                        firstName: json.firstName,
                        lastName: json.lastName,
                        bio: json.bio)
                    let profile = Profile(from: profileResult)
                    completion(.success(profile))
                } catch let error {
                    completion(.failure(error))
                }
                
                self.task = nil
                if error != nil {
                    self.lastToken = nil
                }
            }
        }
        self.task = task
        task.resume()
    }
    
    func requestUser(token: String) -> URLRequest {
        
        let userURLString = defaultBaseURLString + "me"
        
        guard let url = URL(string: userURLString)
        else { fatalError("Failed to create URL") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    struct ProfileResult: Decodable {
        let username: String
        let firstName: String
        let lastName: String
        let bio: String
        
        enum CodingKeys: String, CodingKey {
            case username = "username"
            case firstName = "first_name"
            case lastName = "last_name"
            case bio = "bio"
        }
    }

    struct Profile {
        var username: String
        var loginName: String
        var bio: String
        var name: String {
            return "\(firstName) \(lastName)"
        }

        init(from result: ProfileResult) {
            username = result.username
            loginName = "@" + result.username
            bio = result.bio
            firstName = result.firstName
            lastName = result.lastName
        }

        private let firstName: String
        private let lastName: String
    }
}





//func profileRequest(token: String) -> URLRequest {
//    var request = URLRequest.makeHTTPRequest(path: "/me", httpMethod: "GET")
//    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//    return request
//}

//    private (set) var token: String? {
//        get {
//            return OAuth2TokenStorage().token
//        }
//        set {
//            OAuth2TokenStorage().token = newValue
//        }
//    }
