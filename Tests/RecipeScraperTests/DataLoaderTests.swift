import Testing
import Foundation
@testable import RecipeScraper

@Suite("DataLoaderTests") struct DataLoaderTests {

    @Test func testLoadDataSuccess() async throws {

        let expectedData = "Test Data".data(using: .utf8)!
        let mockNetworking = NetworkingMock(result: .success(expectedData))
        let dataLoader = DataLoader(networking: mockNetworking)
        let urlString = "https://example.com"


        let data = try await dataLoader.loadData(from: urlString)

        #expect(data == expectedData)
    }

    @Test func testLoadDataFailure() async {

        let expectedError = URLError(.notConnectedToInternet)
        let mockNetworking = NetworkingMock(result: .failure(expectedError))
        let dataLoader = DataLoader(networking: mockNetworking)
        let urlString = "https://example.com"

        do {
            let _ = try await dataLoader.loadData(from: urlString)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? URLError == expectedError)
        }
    }
}
