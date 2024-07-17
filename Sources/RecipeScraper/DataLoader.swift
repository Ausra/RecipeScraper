import Foundation

public protocol Networking {
    func data(
        from url: URL
    ) async throws -> (Data, URLResponse)
}

extension URLSession: Networking {}

public protocol DataLoaderProtocol {
    func loadData(from urlString: String) async throws -> Data?
}

public struct DataLoader: DataLoaderProtocol {
    private let networking: Networking

    public init(networking: Networking = URLSession.shared) {
        self.networking = networking
    }

    public func loadData(from urlString: String) async throws -> Data? {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, _) = try await networking.data(from: url)
        return data
    }
}

