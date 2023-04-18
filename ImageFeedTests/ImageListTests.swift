@testable import ImageFeed
import XCTest

final class ImageListViewPresenterSpy: ImageListViewPresenterProtocol {
    var getPhotosCalled = false
    var loadPhotosNextPagesCalled = false
    var changeLikeCalled = false
    var view: ImagesListViewControllerProtocol?
    
    func getPhotos() -> [Photo] {
        getPhotosCalled = true
        return [Photo]()
    }
    
    func sendPhotosNextPage() {
        loadPhotosNextPagesCalled = true
    }
    
    func sendChangedLike(photo: Photo, completion: @escaping (Result<Void, Error>) -> Void) {
        
    }
    
    
}

final class ImageListViewTest: XCTestCase {
    func testFetchArrayPhotos() {
        let viewController = ImagesListViewController()
        let presenter = ImageListViewPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        
        _ = viewController.view
        
        XCTAssertTrue(presenter.getPhotosCalled)
    }
    
    func testFetchPhotosNextPage() {
        let viewController = ImagesListViewController()
        let presenter = ImageListViewPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        
        _ = viewController.view
        
        XCTAssertTrue(presenter.loadPhotosNextPagesCalled)
    }
}
