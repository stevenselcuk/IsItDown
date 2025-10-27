import Alamofire
import Foundation
import SwiftUI

struct Result: Codable {
    var noInternet: Bool = false
    var urlError: Bool = false
    var isDown: Bool = false
    var statusCode: Int = 200
    var responseTime: Double = 0.0
    var errorDescription: String?
}

final class Checker {
    static let `default`: Checker = Checker()

    func check(url: String) async -> Result {
        if !Reachability.isConnectedToNetwork() {
            return Result(noInternet: true, statusCode: 997, errorDescription: "🔌 No internet connection.")
        }

        guard let validURL = URL(string: url) else {
            return Result(urlError: true, isDown: true, statusCode: 998, errorDescription: "⛓️‍💥 The provided URL is invalid.")
        }
        
        let request = AF.request(validURL, method: .get).validate(statusCode: 200 ..< 500)
        let response = await request.serializingString().response
        
        let duration = response.metrics?.taskInterval.duration ?? 0.0
        let statusCode = response.response?.statusCode ?? 500

        switch response.result {
        case .success:
            if (200...299).contains(statusCode) {
                return Result(isDown: false, statusCode: statusCode, responseTime: duration, errorDescription: nil)
            } else {
                let description = HTTPURLResponse.localizedString(forStatusCode: statusCode)
                return Result(isDown: true, statusCode: statusCode, responseTime: duration, errorDescription: "Client Error: \(description)")
            }
        case .failure(let error):
            let finalStatusCode = response.response?.statusCode ?? 999
            return Result(urlError: true, isDown: true, statusCode: finalStatusCode, responseTime: duration, errorDescription: error.localizedDescription)
        }
    }
}
