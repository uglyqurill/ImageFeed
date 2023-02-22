import UIKit
import Foundation

// MARK: - HTTP Requset

//fileprivate let defaultBaseURL = URL(string: "https://api.unsplash.com")!

extension URLRequest {
    static func makeHTTPRequest(
        path: String,
        httpMethod: String,
        baseURL: URL = defaultBaseURL
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = httpMethod
        return request
    }
}

// MARK: - Network Connection

enum NetworkError1: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

extension URLSession {
    func data(
        for request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) -> URLSessionTask {
        let fulfillCompletion: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        
        let task = dataTask(with: request, completionHandler: { data, response, error in // object обёртка над дататаском
            if let data = data,
               let response = response,
               let statusCode = (response as? HTTPURLResponse)?.statusCode
            {
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletion(.success(data))
                } else {
                    fulfillCompletion(.failure(NetworkError1.httpStatusCode(statusCode)))
           
                }
            } else if let error = error {
                fulfillCompletion(.failure(NetworkError1.urlRequestError(error)))
            } else {
                fulfillCompletion(.failure(NetworkError1.urlSessionError))
            }
        })
        task.resume()
        return task
    }
    
}



