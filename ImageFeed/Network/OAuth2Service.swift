//
//  OAuth2Service.swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 08.02.2023.
//

import Foundation

// MARK: - Слой доступа к сервису (Service Access Layer)

final class OAuth2Service {
    static let shared = OAuth2Service()

    private let urlSession = URLSession.shared
    private var task: URLSessionTask?
    private var lastCode: String?

    private (set) var authToken: String? {
        get {
            return OAuth2TokenStorage().token
        }
        set {
            OAuth2TokenStorage().token = newValue
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
    private func object( 
        for request: URLRequest,
        completion: @escaping (Result<OAuthTokenResponseBody, Error>) -> Void
    ) -> URLSessionTask {
        let decoder = JSONDecoder()
        return urlSession.data(for: request) { (result: Result<Data, Error>) in
            let response = result.flatMap { data -> Result<OAuthTokenResponseBody, Error> in
                Result { try decoder.decode(OAuthTokenResponseBody.self, from: data) }
            }
            completion(response)
        }
    }

    private func authTokenRequest(code: String) -> URLRequest? {
        let urlString = "https://unsplash.com/oauth/token"
        var urlComponents = URLComponents(string: urlString)
        urlComponents?.queryItems = [
                    URLQueryItem(name: "client_id", value: accessKey),
                    URLQueryItem(name: "client_secret", value: secretKey),
                    URLQueryItem(name: "redirect_uri", value: redirectURI),
                    URLQueryItem(name: "code", value: code),
                    URLQueryItem(name: "grant_type", value: "authorization_code")
                ]
        
        guard let url = urlComponents?.url else { fatalError("Failed to create URL")  }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        return request

    }

}

//final class OAuth2Service {
//    
//    //MARK: - Enumerations
//    private enum NetworkError: Error {
//        case codeError
//    }
//    
//    
//    //MARK: - Properties
//    let unsplashAuthorizePostURLString = "https://unsplash.com/oauth/token"
//    private let session = URLSession.shared
//    private var task: URLSessionTask?
//    private var lastCode: String?
//    
//    
//    //MARK: - Methods
//    func fetchOAuthToken(code: String, completion: @escaping (Result<String, Error>) -> Void){
//        
//        assert(Thread.isMainThread)
//        if lastCode == code { return }
//        task?.cancel()
//        lastCode = code
//        
//        let request = makeRequest(code: code)
//        
//        let task = self.session.objectTask(for: request) { [weak self]
//            (result: Result<OAuthTokenResponseBody, Error>) in
//            guard let self = self else {return}
//            DispatchQueue.main.async {
//                switch result {
//                case .success(let jsonData):
//                    //OAuth2TokenStorage().bearerToken = jsonData.accessToken
//                    completion(.success(jsonData.accessToken))
//                    self.task = nil
//                case .failure(let error):
//                    completion(.failure(error))
//                    self.lastCode = nil
//                }
//            }
//        }
//        self.task = task
//        task.resume()
//    }
//    
//    func makeRequest (code: String) -> URLRequest {
//        
//        var urlComponents = URLComponents(string: self.unsplashAuthorizePostURLString)!
//        urlComponents.queryItems = [
//            URLQueryItem(name: "client_id", value: accessKey),
//            URLQueryItem(name: "client_secret", value: secretKey),
//            URLQueryItem(name: "redirect_uri", value: redirectURI),
//            URLQueryItem(name: "code", value: code),
//            URLQueryItem(name: "grant_type", value: "authorization_code")
//        ]
//        
//        guard let url = urlComponents.url else { fatalError("Failed to create URL") }
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        return request
//    }
//}
