import XCTest
@testable import ImageFeed

final class ProfileViewPresenterSpy: ProfileViewPresenterProtocol {
    var getProfileCalled: Bool = false
    var getAvatarCalled: Bool = false
    var logoutCalled: Bool = false
    var viewDidLoadCalled: Bool = false
    var profile: Profile = .init(from: ProfileResult(username: "test", firstName: "test", lastName: "test", bio: "test"))
    
    func viewDidLoad() {
        viewDidLoadCalled = true
        
    }
    
   var view: ProfileViewControllerProtocol?
   
   func getProfile() -> Profile? {
       getProfileCalled = true
       return profile
   }
   
   func getAvatar() -> URL? {
       getAvatarCalled = true
       return URL(string: "testString")
   }
   
   func logout() {
       logoutCalled = true
   }
}



final class ProfileViewTest: XCTestCase {
    func testGetProfile() {
        let viewController = ProfileViewController()
        let presenter = ProfileViewPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        _ = viewController.view
        
        XCTAssertTrue(presenter.getProfileCalled)
    }
    
    func testGetAvatar() {
        let viewController = ProfileViewController()
        let presenter = ProfileViewPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        _ = viewController.view
        
        XCTAssertTrue(presenter.getAvatarCalled)
    }
    
    func testLogout() {
        let viewController = ProfileViewController()
        let presenter = ProfileViewPresenterSpy()
        
        viewController.presenter = presenter
        presenter.view = viewController
        _ = viewController.view
        
        XCTAssertTrue(presenter.logoutCalled)
    }

}
