//
//  ImagesListService.swift
//  ImageFeed
//
//  Created by Кирилл Брызгунов on 26.02.2023.
//

import Foundation
import SwiftKeychainWrapper

class ImageListService {

    //static let DidChangeNotification = Notification.Name("ImagesListServiceDidChange")
    static let didChangeNotification = Notification.Name(rawValue: "ImageListServiceDidChange")
    private let urlSession = URLSession.shared
    static let shared = ImageListService()
    
    var photos: [Photo] = []
    var photosPerPage = 10
    
    private var isFetchingNextPage = false
    private var lastLoadedPage: Page?
    private var lastToken: String?
    private var task: URLSessionTask?
    private let tokenStorage = SwiftKeychainWrapper()
    
    //private(set) var profile: Profile?
    
    func fetchPhotosNextPage() {
        guard let token = tokenStorage.getBearerToken() else { return }
        
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
        
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let task = urlSession.objectTask(for: request) { [weak self] (result: Result<PhotoResult, Error>) in
            guard let self = self else { return }
            
            self.isFetchingNextPage = false
            
            switch result {
            case .success(let json):
                let photoResult: [PhotoResult] = [json]
                DispatchQueue.main.async {
                    self.photos += photoResult.map {
                        self.convert(photoResult: $0)
                    }
                }
                NotificationCenter.default.post(name: ImageListService.didChangeNotification, object: self)
                self.lastLoadedPage = Page(number: nextPage, photos: photoResult)
            case .failure(let error):
                print("Error fetching photos: \(error)")
            }
        }
        self.task = task
        task.resume()
    }
    
    private func convert(photoResult: PhotoResult) -> Photo {
        return Photo(from: photoResult)
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

