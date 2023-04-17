import Foundation

protocol ImageListViewPresenterProtocol {
    func getPhotos() -> [Photo]
    func sendPhotosNextPage()
    func sendChangedLike(photo: Photo, completion: @escaping (Result<Void, Error>) -> Void)
}

final class ImageListViewPresenter: ImageListViewPresenterProtocol {
    private let imageListService: ImagesListService
    
    init(viewController: ImagesListViewControllerProtocol, imageListService: ImagesListService = .shared) {
        self.imageListService = imageListService
    }
    
    func getPhotos() -> [Photo] {
        imageListService.photos
    }
    
    func sendPhotosNextPage() {
        imageListService.fetchPhotosNextPage()
    }
    
    func sendChangedLike(photo: Photo, completion: @escaping (Result<Void, Error>) -> Void) {
        imageListService.changeLike(photoId: photo.id, isLike: photo.isLiked, completion)
    }
    
    
}
