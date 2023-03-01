//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 26.02.2023.
//

import Foundation

class ImagesListService {

    static let DidChangeNotification = Notification.Name("ImagesListServiceDidChange")
    private let urlSession = URLSession.shared

    var photos: [Photo] = []
    var photosPerPage = 10

    private var isFetchingNextPage = false
    private var lastLoadedPage: Page?
    private var lastToken: String?
    private var task: URLSessionTask?
    private let tokenStorage = SwiftKeychainWrapper()

    func fetchPhotosNextPage(_ token: String, completion: @escaping (Result<[Photo], Error>) -> Void) {

        if task != nil { return }

        guard !isFetchingNextPage else {
            return
        }

        let nextPage = lastLoadedPage == nil ? 1 : lastLoadedPage!.number + 1
        isFetchingNextPage = true

        var request = URLRequest.makeHTTPRequest(
            path: "/photos"
            + "?page=\(nextPage)"
            + "&per_page=\(photosPerPage)",
            httpMethod: "GET",
            baseURL: defaultBaseURL)

        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else {
                return
            }
            self.isFetchingNextPage = false
            switch result {
            case .success(let photoResults):
                let photos = photoResults.map { Photo(from: $0) }
                DispatchQueue.main.async {
                    self.photos += photos
                }
                NotificationCenter.default.post(name: ImagesListService.DidChangeNotification, object: self)
                self.lastLoadedPage = Page(number: nextPage, photos: photoResults)
                completion(.success(photos))

            case .failure(let error):
                print("Error fetching photos: \(error)")
                completion(.failure(error))
            }
        }
        self.task = task
        task.resume()
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
    
    init(from result: PhotoResult) {
        id = result.id
        size = CGSize(width: result.width, height: result.height)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        createdAt = dateFormatter.date(from: result.createdAt)
        welcomeDescription = result.description
        thumbImageURL = result.urls.thumb
        largeImageURL = result.urls.full
        isLiked = result.likedByUser
    }
}

struct Page {
    let number: Int
    let photos: [PhotoResult]
}


/*
 import Foundation
 
 class ImagesListService {
 
 static let DidChangeNotification = Notification.Name("ImagesListServiceDidChange")
 private let urlSession = URLSession.shared
 
 var photos: [Photo] = []
 var photosPerPage = 10
 
 private var isFetchingNextPage = false
 private var lastLoadedPage: Page?
 private var lastToken: String?
 private var task: URLSessionTask?
 private let tokenStorage = SwiftKeychainWrapper()
 
 //private(set) var profile: Profile?
 
 
 func fetchPhotosNextPage(_ token: String, completion: @escaping (Result<[PhotoResult], Error>) -> Void) {
 
 //guard let token = tokenStorage.getBearerToken() else { return }
 
 if task != nil { return }
 
 guard !isFetchingNextPage else {
 return
 }
 
 let nextPage = lastLoadedPage == nil ? 1 : lastLoadedPage!.number + 1
 isFetchingNextPage = true
 
 var request = URLRequest.makeHTTPRequest(
 path: "/photos"
 + "?page=\(nextPage)"
 + "&&per_page=\(photosPerPage)",
 httpMethod: "GET",
 baseURL: defaultBaseURL)
 
 let task = urlSession.objectTask(for: request) { (result: Result<PhotoResult, Error>) in
 guard let self = self else {
 return
 }
 self.isFetchingNextPage = false
 switch result {
 case .success(let json):
 let photoResult: [PhotoResult] = PhotoResult(
 id: json.id,
 createdAt: json.createdAt,
 updatedAt: json.updatedAt,
 width: json.width,
 height: json.height,
 color: json.color,
 blurHash: json.blurHash,
 likes: json.likes,
 likedByUser: json.likedByUser,
 description: json.description,
 urls: json.urls
 )
 DispatchQueue.main.async {
 self.photos += photoResult.map {
 self.convert(photoResult: $0)
 }
 }
 NotificationCenter.default.post(name: ImagesListService.DidChangeNotification, object: self)
 self.lastLoadedPage! += 1
 completion(.success(photoResult))
 
 case .failure(let error):
 print("Error fetching photos: \(error)")
 }
 }
 self.task = task
 task.resume()
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
 
 init(from result: PhotoResult) {
 id = result.id
 size = CGSize(width: result.width, height: result.height)
 createdAt = ISO8601DateFormatter().date(from: result.createdAt)
 welcomeDescription = result.description
 thumbImageURL = result.urls.thumb
 largeImageURL = result.urls.full
 isLiked = result.likedByUser
 }
 }
 
 struct Page {
 let number: Int
 let photos: [PhotoResult]
 }
 
 struct PhotoResult: Decodable {
 let id: String
 let createdAt: String
 let updatedAt: String
 let width: Int
 let height: Int
 let color: String
 let blurHash: String
 let likes: Int
 let likedByUser: Bool
 let description: String
 //let user: ProfileResult
 let urls: UrlsResult
 
 enum CodingKeys: String, CodingKey {
 case id = "id"
 case createdAt = "created_at"
 case updatedAt = "updated_at"
 case width = "width"
 case height = "height"
 case color = "color"
 case blurHash = "blur_hash"
 case likes = "likes"
 case likedByUser = "liked_by_user"
 case description = "description"
 //case user = "user"
 case urls = "urls"
 }
 }
 
 struct UrlsResult: Decodable {
 let raw: String
 let full: String
 let regular: String
 let small: String
 let thumb: String
 
 enum CodingKeys: String, CodingKey {
 case raw = "raw"
 case full = "full"
 case regular = "regular"
 case small = "small"
 case thumb = "thumb"
 }
 }

*/
