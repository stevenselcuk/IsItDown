//
//  CurrencyConverter.swift
//  YouBar
//
//  Created by Steven J. Selcuk on 16.08.2022.
//

import Alamofire
import Foundation
import SwiftUI

struct Result: Codable {
    var noInternet: Bool = false
    var urlError: Bool = false
    var isDown: Bool = false
    var statusCode: Int = 200
    var error: String = ""
}

final class Checker {
    static let `default`: Checker = Checker()

    func check(url: String = "https://google.com", completion: @escaping (Result) -> Void) {
        if Reachability.isConnectedToNetwork() == false { completion(Result(noInternet: true, urlError: false, isDown: false, statusCode: 997, error: "Not Connected")) }

        guard let url = URL(string: url) else {
            return completion(Result(noInternet: false, urlError: true, isDown: true, statusCode: 998, error: "Bad URL"))
        }

        AF.request(url,
                   method: .get,
                   parameters: nil,
                   encoding: JSONEncoding.default,
                   headers: nil)
           // .validate(statusCode: 200 ..< 500)
            .responseString(completionHandler:{ response in
                switch response.result {
                case let .success(data):
                    switch response.response?.statusCode {
                    case 200, 204:
                        completion(Result(noInternet: false, urlError: false, isDown: false, statusCode: response.response?.statusCode ?? 200, error: "Success"))
                    case 429:
                        completion(Result(noInternet: false, urlError: false, isDown: true, statusCode: response.response?.statusCode ?? 429, error: "Success 429"))
                    default:
                        completion(Result(noInternet: false, urlError: false, isDown: true, statusCode: response.response?.statusCode ?? 500, error: "Unknown Error"))
                    }
                case let .failure(error):
                    print(error)
                    completion(Result(noInternet: false, urlError: true, isDown: false, statusCode: 999, error: "Server Down"))
                }
            })
    }
}
