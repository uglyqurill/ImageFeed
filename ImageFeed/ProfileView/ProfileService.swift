import Foundation
import UIKit

final class ProfileService {
    
    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastToken: String?
    static let shared = ProfileService()
    
    private(set) var profile: Profile?
    
    func fetchProfile(_ token: String, completion: @escaping (Result<Profile, Error>) -> Void) {
        assert(Thread.isMainThread)
        
        if lastToken == token { return }
        task?.cancel()
        lastToken = token
        
        let request = requestUser(token: token)
        
        let task = urlSession.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
            switch result {
            case .success(let json):
                let profileResult = ProfileResult(
                    username: json.username,
                    firstName: json.firstName,
                    lastName: json.lastName,
                    bio: json.bio ?? "")
                self.profile = Profile(from: profileResult)
                completion(.success(self.profile!))
            case .failure(let error):
                completion(.failure(error))
            }
            
            self.task = nil
            if case let .failure(error) = result {
                self.lastToken = nil
            }
        }
        self.task = task
        task.resume()
    }
    
    func requestUser(token: String) -> URLRequest {
        
        let userURLString = Constants.defaultBaseURLString + "me"
        
        guard let url = URL(string: userURLString)
        else { assertionFailure("Failed to create URL"); return URLRequest(url: URL(string: "")!) } // вот так правильно?
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    struct ProfileResult: Decodable {
        let username: String
        let firstName: String
        let lastName: String
        let bio: String?
        
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
        private let firstName: String
        private let lastName: String
        var name: String {
            return "\(firstName) \(lastName)"
        }

        init(from result: ProfileResult) {
            username = result.username
            loginName = "@" + result.username
            bio = result.bio ?? ""
            firstName = result.firstName
            lastName = result.lastName
        }
    }
}


