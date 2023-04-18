import Foundation

struct Constants {
    static let accessKey = "h9u9IDtscwhLMDSevmIPK0YXBMwvUZVfSCEbykIdB1E"
    static let secretKey = "Ip1ortflUIXhh_r0e1Qs37a01SzAor5fMsr8StqFqm0"
    static let redirectURI = "urn:ietf:wg:oauth:2.0:oob"
    static let accessScope = "public+read_user+write_likes"
    static let defaultBaseURLString = "https://api.unsplash.com/"
    static let defaultBaseURL = URL(string: defaultBaseURLString)!
    static let unsplashUrlString = "https://unsplash.com/oauth/token"
    static let UnsplashAuthorizeURLString = "https://unsplash.com/oauth/authorize"
}

struct AuthConfiguration {
    let accessKey: String
    let secretKey: String
    let redirectURI: String
    let accessScope: String
    let defaultBaseURL: URL
    let authURLString: String
    
    static var standard: AuthConfiguration {
        return AuthConfiguration(accessKey: Constants.accessKey,
                                 secretKey: Constants.secretKey,
                                 redirectURI: Constants.redirectURI,
                                 accessScope: Constants.accessScope,
                                 defaultBaseURL: Constants.defaultBaseURL,
                                 authURLString: Constants.UnsplashAuthorizeURLString)
    }
}
