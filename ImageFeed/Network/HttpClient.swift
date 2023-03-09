import UIKit
import Foundation

// MARK: - HTTP Requset

//extension URLRequest {
//    static func makeHTTPRequest(
//        path: String,
//        httpMethod: String,
//        baseURL: URL = defaultBaseURL
//    ) -> URLRequest {
//        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
//        request.httpMethod = httpMethod
//        return request
//    }
//}

enum HttpClientError: Error {
    case httpStatusCode(Int)
    case urlRequestError(Error)
    case urlSessionError
}

final class HttpClient: NSObject {
    private let session: URLSession

    init(session: URLSession) {
        self.session = session
    }

    @discardableResult
    func data(for request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) -> URLSessionTask {
        let fulfillCompletionOnTheMainThread: (Result<Data, Error>) -> Void = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, let response = response, let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if 200 ..< 300 ~= statusCode {
                    fulfillCompletionOnTheMainThread(.success(data))
                } else {
                    fulfillCompletionOnTheMainThread(.failure(HttpClientError.httpStatusCode(statusCode)))
                }
            } else if let error = error {
                fulfillCompletionOnTheMainThread(.failure(HttpClientError.urlRequestError(error)))
            } else {
                fulfillCompletionOnTheMainThread(.failure(HttpClientError.urlSessionError))
            }
        })
        return task
    }
}

extension HttpClient: URLSessionDelegate { }

extension HttpClient {
    @discardableResult
    func object<T: Decodable>(for request: URLRequest, completion: @escaping (Result<T, Error>) -> Void) -> URLSessionTask {
        let decoder = JSONDecoder()
        return data(for: request) { (result: Result<Data, Error>) in
            let response = result.flatMap { data -> Result<T, Error> in
                Result { try decoder.decode(T.self, from: data) }
            }
            completion(response)
        }
    }
}




