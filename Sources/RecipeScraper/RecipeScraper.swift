import Foundation
import SwiftSoup

protocol Networking {
    func data(
        from url: URL
    ) async throws -> (Data, URLResponse)
}

extension URLSession: Networking {}

protocol DataLoaderProtocol {
    func loadData(from urlString: String) async throws -> Data
}

public struct DataLoader: DataLoaderProtocol {
    private let networking: Networking
    
    init(networking: Networking = URLSession.shared) {
        self.networking = networking
    }
    
    public func loadData(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await networking.data(from: url)
        return data
    }
}

public struct RecipeParser {
    
    private let dataLoader: DataLoaderProtocol
    
    init(dataLoader: DataLoaderProtocol = DataLoader()) {
        self.dataLoader = dataLoader
    }
    
    public func parseHTML(from url: String) async throws -> String {
        let data = try await dataLoader.loadData(from: url)
        let html = String(decoding: data, as: UTF8.self)
        
        return html
    }
}
