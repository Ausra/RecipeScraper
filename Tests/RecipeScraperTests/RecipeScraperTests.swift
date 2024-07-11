import Testing
import SwiftSoup
@testable import RecipeScraper

struct MockNetworkService: NetworkService {
    let mockHTML: String
    
    func fetchHTML(from urlString: String) async throws -> String {
        // Return a sample HTML string
        return mockHTML
    }
}

@Suite("HTMLScraperTests")
struct HTMLScraperTests {
    
    static let mockHTML = "<html><head><title>Mock</title></head><body><p>Mock HTML content</p></body></html>"
    
    func normalizeHTML(_ html: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        return try document.outerHtml().replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
    }
    
    @Test func testScraper() async throws {
        let scraper = RecipeScraper(networkService: MockNetworkService(mockHTML: HTMLScraperTests.mockHTML))
        let html = try await scraper.parseHTML(from: "https://example.com/recipe")
        
        let normalizedHTML = try normalizeHTML(html)
        let expectedNormalizedHTML = try normalizeHTML(HTMLScraperTests.mockHTML)
        
        #expect(normalizedHTML == expectedNormalizedHTML)
    }
}
