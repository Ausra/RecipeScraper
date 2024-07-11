import Foundation
import SwiftSoup

public protocol NetworkService {
    func fetchHTML(from urlString: String) async throws -> String
}

public struct RealNetworkService: NetworkService {
    public init() {} 
    
    public func fetchHTML(from urlString: String) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return String(decoding: data, as: UTF8.self)
    }
}

public struct RecipeScraper {
    private let networkService: NetworkService
    
    public init(networkService: NetworkService = RealNetworkService()) {
        self.networkService = networkService
    }
    
    public func parseHTML(from urlString: String) async throws -> String {
        let html = try await networkService.fetchHTML(from: urlString)
        let document = try SwiftSoup.parse(html)
        let parsedHTML = try document.outerHtml()
        return parsedHTML
    }
}
