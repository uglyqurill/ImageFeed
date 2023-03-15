import Foundation

final class ImagesListService {

    static let didChangeNotification = Notification.Name(rawValue: "ImageListServiceDidChange")
    private let urlSession = URLSession.shared
    static let shared = ImagesListService()
    
    private lazy var dateFormatter: ISO8601DateFormatter = {
        return ISO8601DateFormatter()
    }()
    
    private let notificationCenter = NotificationCenter.default
    var photos: [Photo] = []
    private var photosPerPage = 10
    private var loadingPage: Page?
    private var lastLoadedPage: Page?
    
    private var isFetchingNextPage = false
   
    private var lastToken: String?
    private var task: URLSessionTask?
    private let tokenStorage = SwiftKeychainWrapper()
    
    func fetchPhotosNextPage() {
        let nextPage: Page
        if let lastLoadedPage = lastLoadedPage {
            nextPage = Page(number: lastLoadedPage.number + 1, perPage: 10)
        }
        else {
            nextPage = Page(number: 1, perPage: 10)
        }

        guard task == nil || self.loadingPage != nextPage else { return }
        task?.cancel()
        self.loadingPage = nextPage

        let request = photosRequest(page: nextPage.number, perPage: nextPage.perPage)
        let task = urlSession.objectTask(for: request, completion: { [weak self] (result: Result<[PhotoResult], Error>) in
            guard let self = self else { return }

            self.task = nil

            guard case .success(let photosResult) = result else {
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
    
    private func photosRequest(page: Int, perPage: Int) -> URLRequest {
        makeRequest(path: "/photos?page=\(page)&&per_page=\(perPage)")
    }
    
    private func makeRequest(
        path: String,
        httpMethod: String = "GET",
        baseURL: URL = Constants.baseURL
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
    
    func getLargeImageCellURL(indexPath: IndexPath) -> URL {
        let stringUrl = photos[indexPath.row].largeImageURL
        guard let url = URL(string: stringUrl) else { fatalError("Don't have URL for large photo")}
        return url
    }
}

