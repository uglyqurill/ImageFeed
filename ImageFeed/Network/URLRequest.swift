//
//import WebKit
//import Foundation
//
//// Создание URL с использованием [стандартного конструктора]
//let url = URL(string: "https://api.unsplash.com/me")!
//// Создание URL с использованием [URLComponents]
//var urlComponents = URLComponents()
//urlComponents.scheme = "https"
//urlComponents.host = "api.unsplash.com"
//urlComponents.path = "/me"
//let url = urlComponents.url!
//// Создание HTTP-запроса [с заданным URL]
//var request = URLRequest(url: url)
//// Изменение [HTTP-глагола]
//request.httpMethod = "PUT"
//// Установка [HTTP-заголовка]
//let authToken = OAuth2TokenStorage().token
//request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
//// Передача объекта через [тело запроса]
//struct User: Encodable {
//  let username: String
//}
//request.httpBody = try JSONEncoder().encode(User(username: "Test"))
