import Foundation
import SwiftKeychainWrapper

// MARK: - Слой доступа к сервису (Service Access Layer)

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?
    private let authTokenKey = "authToken"
    
    private (set) var authToken: String? {
        get {
            return SwiftKeychainWrapper().getBearerToken()
        }
        set {
            SwiftKeychainWrapper().setBearerToken(token: newValue)
        }
    }

    func fetchOAuthToken(_ code: String, completion: @escaping (Result<String, Error>) -> Void) {
        assert(Thread.isMainThread)

        if lastCode == code { return }
        task?.cancel()
        lastCode = code

        guard let request = authTokenRequest(code: code) else { return }

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<OAuthTokenResponseBody, Error>) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let body):
                    let authToken = body.accessToken
                    self.authToken = authToken
                    completion(.success(authToken))
                case .failure(let error):
                    self.lastCode = nil
                    completion(.failure(error))
                }
                self.task = nil
            }
        }

        self.task = task
        task.resume()
    }
}

extension OAuth2Service {
    
    private func authTokenRequest(code: String) -> URLRequest? {
        let urlString = Constants.unsplashUrlString
        var urlComponents = URLComponents(string: urlString)
        urlComponents?.queryItems = [
            URLQueryItem(name: "client_id", value: Constants.accessKey),
            URLQueryItem(name: "client_secret", value: Constants.secretKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
                    URLQueryItem(name: "code", value: code),
                    URLQueryItem(name: "grant_type", value: "authorization_code")
                ]

        guard let url = urlComponents?.url else {
            assertionFailure("Failed to create URL"); return URLRequest(url: URL(string: "")!)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request

    }

}
