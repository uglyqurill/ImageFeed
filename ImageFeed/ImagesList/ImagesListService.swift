//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 26.02.2023.
//

import Foundation
import SwiftKeychainWrapper

class ImagesListService {

    static let didChangeNotification = Notification.Name(rawValue: "ImageListServiceDidChange")
    private let urlSession = URLSession.shared
    static let shared = ImagesListService()
    //private let httpClient: HttpClient
    
//    init(httpClient: HttpClient) {
//        self.httpClient = httpClient
//    }
    
    private lazy var dateFormatter: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
    
    private let notificationCenter = NotificationCenter.default
    var photos: [Photo] = []
    var photosPerPage = 10
    private var loadingPage: Page?
    private var lastLoadedPage: Page?
    
    private var isFetchingNextPage = false
   
    private var lastToken: String?
    private var task: URLSessionTask?
    private let tokenStorage = SwiftKeychainWrapper()
    
    //private(set) var profile: Profile?
    
    func fetchPhotosNextPage() {
        let nextPage: Page
        if let lastLoadedPage = lastLoadedPage {
            nextPage = Page(number: lastLoadedPage.number + 1, perPage: 10)
        }
        else {
            nextPage = Page(number: 1, perPage: 10)
        }

        // Already fetching for a given authToken
        guard task == nil || self.loadingPage != nextPage else { return }
        // In case a task for a different token is in progress - cancel it
        task?.cancel()
        // Remember the page to prevent double-loading
        self.loadingPage = nextPage

        let request = photosRequest(page: nextPage.number, perPage: nextPage.perPage)
        //let task = urlSession.objectTask(for: request) { (result: Result<ProfileResult, Error>) in
        let task = urlSession.objectTask(for: request, completion: { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }

            self.task = nil

            guard case .success(let photosResult) = result else {
                // Don't do anything, another fetch will be triggered if user scrolls down
                return
            }

            let photos = photosResult.map { photoResult in
                Photo(
                    id: photoResult.id,
                    size: CGSize(width: photoResult.width, height: photoResult.height),
                    createdAt: self.date(from: photoResult.createdAt),
                    welcomeDescription: photoResult.welcomeDescription,
                    thumbImageURL: photoResult.urls.thumb,
                    largeImageURL: photoResult.urls.full,
                    isLiked: photoResult.likedByUser
                )
            }

            self.photos += photos
            self.lastLoadedPage = nextPage
            self.notificationCenter.post(name: Self.didChangeNotification, object: self)
        })

        task.resume()
        self.task = task
    }

    
//    private func convert(photoResult: PhotoResult) -> Photo {
//        return Photo(from: photoResult)
//    }
    
    private func photosRequest(page: Int, perPage: Int) -> URLRequest {
        makeRequest(path: "/photos?page=\(page)&&per_page=\(perPage)")
    }
    
    private func makeRequest(
        path: String,
        httpMethod: String = "GET",
        baseURL: URL = URL(string: "https://api.unsplash.com")!
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: path, relativeTo: baseURL)!)
        request.httpMethod = httpMethod
        if let bearerToken = tokenStorage.getBearerToken() {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func date(from string: String) -> Date? {
        dateFormatter.date(from: string)
    }

}

extension ImagesListService {
//    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
//        let request = isLike ? likeRequest(photoId: photoId) : unlikeRequest(photoId: photoId)
//
//        let task = urlSession.objectTask(for: request, completion: { [weak self] (result: Result<[PhotoResult], Error>) in
//            //let task = httpsClient.data(for: request) { result in
//            switch result {
//            case .success:
//                guard let updatedPhotoIndex = self!.photos.firstIndex(where: { $0.id == photoId })
//                else { return }
//                let oldPhoto = self!.photos[updatedPhotoIndex]
//                let newPhoto = oldPhoto.withToggledLike()
//                self!.photos = self!.photos.withReplaced(itemAt: updatedPhotoIndex, newValue: newPhoto)
//                completion(.success(()))
//
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//        task.resume()
//    }
    
    func changeLike(photoId: String, isLike: Bool, _ completion: @escaping (Result<Void, Error>) -> Void) {
         enum LikeError: Error {
             case photoNotFound
         }

         let request = isLike ? likeRequest(photoId: photoId) : unlikeRequest(photoId: photoId)

         let task = urlSession.objectTask(for: request) { [weak self] (result: Result<LikeResult, Error>) in
             guard let self else { return }
             switch result {
             case .success:
                 if let index = self.photos.firstIndex(where: { $0.id == photoId }) {
                     let photo = self.photos[index]
                     let newPhoto = Photo(
                         id: photo.id,
                         size: photo.size,
                         createdAt: photo.createdAt,
                         welcomeDescription: photo.welcomeDescription,
                         thumbImageURL: photo.thumbImageURL,
                         largeImageURL: photo.largeImageURL,
                         isLiked: !photo.isLiked
                     )
                     self.photos[index] = newPhoto
                     completion(.success(()))
                 } else {
                     completion(.failure(LikeError.photoNotFound))
                 }
             case .failure(let error):
                 completion(.failure(error))
             }
         }

         task.resume()
     }
    
    func likeRequest(photoId: String) -> URLRequest {
        makeRequest(path: "/photos/\(photoId)/like", httpMethod: "POST")
    }
    
    func unlikeRequest(photoId: String) -> URLRequest {
        makeRequest(path: "/photos/\(photoId)/like", httpMethod: "DELETE")
    }
}

struct Photo {
    let id: String
    let size: CGSize
    let createdAt: Date?
    let welcomeDescription: String?
    let thumbImageURL: String
    let largeImageURL: String
    let isLiked: Bool
}

extension Photo {
    func withToggledLike() -> Photo {
        Photo(
            id: id,
            size: size,
            createdAt: createdAt,
            welcomeDescription: welcomeDescription,
            thumbImageURL: thumbImageURL,
            largeImageURL: largeImageURL,
            isLiked: !isLiked
        )
    }
}

struct Page: Equatable {
    let number: Int
    let perPage: Int
}

struct UrlsResult: Codable {
    let raw, full, regular, small: String
    let thumb: String
}

extension Array {
    func withReplaced(itemAt index: Int, newValue: Element) -> Self {
        var result = self
        result[index] = newValue
        return result
    }
}

struct LikeResult: Decodable {
    let photo: PhotoResult
}

struct PhotoResult: Decodable {
    let id: String
    let createdAt, updatedAt: String
    let width, height: Int
    let color, blurHash, welcomeDescription: String?
    let urls: UrlsResult
    let likedByUser: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case width, height, color
        case blurHash = "blur_hash"
        case welcomeDescription = "description"
        case urls
        case likedByUser = "liked_by_user"
    }
}
