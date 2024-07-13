import Testing
import Foundation
import SwiftSoup
@testable import RecipeScraper

struct NetworkingMock: Networking {
    var result = Result<Data, Error>.success(Data())

    func data(
        from url: URL
    ) async throws -> (Data, URLResponse) {
        try (result.get(), URLResponse())
    }
}

struct DataLoaderMock: DataLoaderProtocol {
    var result: Result<Data, Error>?

    init(result: Result<Data, Error>?) {
        self.result = result
    }

    func loadData(from urlString: String) async throws -> Data? {
        return try result?.get()
    }
}

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

@Suite("HTMLParserTests") struct HTMLParserTests {

    static let mockHTML = "<html><head><title>Mock</title></head><body><p>Mock HTML content</p></body></html>"

    static func normalizeHTML(_ html: String) throws -> String {
        let document = try SwiftSoup.parse(html)
        return try document.outerHtml().replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: " ", with: "")
    }

    @Test func testParser() async throws {
        let data = HTMLParserTests.mockHTML.data(using: .utf8)!

        let dataLoaderMock = DataLoaderMock(result: .success(data))
        let parser = RecipeParser(dataLoader: dataLoaderMock)
        let html = try await parser.parseHTML(from: "https://example.com/recipe")

        let normalizedHTML = try HTMLParserTests.normalizeHTML(html)
        let expectedNormalizedHTML = try HTMLParserTests.normalizeHTML(HTMLParserTests.mockHTML)

        #expect(normalizedHTML == expectedNormalizedHTML)
    }

    @Test func testEmptyHTMLResponse() async throws {
        let data = "".data(using: .utf8)!

        let dataLoaderMock = DataLoaderMock(result: .success(data))
        let parser = RecipeParser(dataLoader: dataLoaderMock)

        do {
            let html = try await parser.parseHTML(from: "https://example.com/empty")
            let normalizedHTML = try HTMLParserTests.normalizeHTML(html)
            let expectedNormalizedHTML = try HTMLParserTests.normalizeHTML("<html><head></head><body></body></html>")
            #expect(normalizedHTML == expectedNormalizedHTML)
        } catch {
            Issue.record("Expected to handle empty HTML response without error")
        }
    }

    @Test func testMalformedHTML() async throws {
        let data = "<html><head><title>Malformed</title></head><body><p>Unclosed tag".data(using: .utf8)!
        let dataLoaderMock = DataLoaderMock(result: .success(data))
        let parser = RecipeParser(dataLoader: dataLoaderMock)

        do {
            let html = try await parser.parseHTML(from: "https://example.com/malformed")
            let normalizedHTML = try HTMLParserTests.normalizeHTML(html)
            let expectedEmptyNormalizedHTML = try HTMLParserTests.normalizeHTML("<html><head></head><body></body></html>")
            #expect(normalizedHTML != expectedEmptyNormalizedHTML)
        } catch {
            Issue.record("Expected to handle malformed HTML without error")
        }
    }

    @Test func testLargeHTMLDocument() async throws {
        let data = String(repeating: "<p>Large Content</p>", count: 10000).data(using: .utf8)!
        let dataLoaderMock = DataLoaderMock(result: .success(data))
        let parser = RecipeParser(dataLoader: dataLoaderMock)

        do {
            let html = try await parser.parseHTML(from: "https://example.com/large")
            let normalizedHTML = try HTMLParserTests.normalizeHTML(html)
            let expectedEmptyNormalizedHTML = try HTMLParserTests.normalizeHTML("<html><head></head><body></body></html>")
            #expect(normalizedHTML != expectedEmptyNormalizedHTML)
        } catch {
            Issue.record("Expected to handle large HTML document without error")
        }
    }
}

@Suite("RecipeJSONParserTests") struct RecipeJSONParserTests {
    let parser = RecipeParser(dataLoader: DataLoaderMock(result: nil))

    @Test func testParseValidRecipeJSON() {
        let validHTML = """
        <html>
            <head>
                <script type="application/ld+json">
                {
                    "@type": "Recipe",
                    "name": "Test Recipe"
                }
                </script>
            </head>
            <body></body>
        </html>
        """

        do {
            let jsonData = try parser.parseRecipeJSON(from: validHTML)
            #expect(jsonData != nil)

            if let json = try JSONSerialization.jsonObject(with: jsonData!, options: []) as? [String: Any] {
                #expect(json["@type"] as? String == "Recipe")
                #expect(json["name"] as? String == "Test Recipe")
            } else {
                Issue.record("Failed to parse JSON data")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func testParseInvalidRecipeJSON() {
        let invalidHTML = """
                {
                    "": "data"
                }
                </script>
            <body>>
        """

        #expect { try parser.parseRecipeJSON(from: invalidHTML) } throws: { error in
            return error as? RecipeParserError == RecipeParserError.noRecipeMetaDataError

        }
    }

    @Test func testParseEmptyHTML() {
        let emptyHTML = "<html><head></head><body></body></html>"

        #expect { try parser.parseRecipeJSON(from: emptyHTML) } throws: { error in
            return error as? RecipeParserError == RecipeParserError.noRecipeMetaDataError
        }
    }

    @Test func testParseInvalidScriptType() {
        let invalidScriptTypeHTML = """
        <html>
            <head>
                <script type="text/javascript">
                {
                    "@type": "Recipe",
                    "name": "Test Recipe"
                }
                </script>
            </head>
            <body></body>
        </html>
        """

        #expect { try parser.parseRecipeJSON(from: invalidScriptTypeHTML) } throws: { error in
            return error as? RecipeParserError == RecipeParserError.noRecipeMetaDataError
        }
    }

    @Test func testParseNestedRecipeJSON() {
        let nestedHTML = """
        <html>
            <head>
                <script type="application/ld+json">
                {
                    "@graph": [
                        {
                            "@type": "Recipe",
                            "name": "Nested Recipe"
                        }
                    ]
                }
                </script>
            </head>
            <body></body>
        </html>
        """

        do {
            let jsonData = try parser.parseRecipeJSON(from: nestedHTML)
            #expect(jsonData != nil)

            if let json = try JSONSerialization.jsonObject(with: jsonData!, options: []) as? [String: Any] {
                #expect(json["@type"] as? String == "Recipe")
                #expect(json["name"] as? String == "Nested Recipe")
            } else {
                Issue.record("Failed to parse JSON data")
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func testParseInvalidJSONInScriptTag() {
        let invalidJSONHTML = """
        <html>
            <head>
                <script type="application/ld+json">
                {
                    "invalidJson": true, // trailing comma makes the JSON invalid
                }
                </script>
            </head>
            <body></body>
        </html>
        """

        #expect { try parser.parseRecipeJSON(from: invalidJSONHTML) } throws: { error in
            return error as? RecipeParserError == RecipeParserError.JSONerror
        }
    }
}

@Suite("DecodeRecipeJSONTests") struct DecodeRecipeJSONTests {

    let parser = RecipeParser(dataLoader: DataLoaderMock(result: nil))

    @Test func testDecodeRecipeJSONSuccess() throws {
        let sampleJSON = """
        {
            "@context": "https://schema.org/",
            "@type": "Recipe",
            "name": "Cupcakes"
        }
        """.data(using: .utf8)!

        do {
            let recipe = try parser.decodeRecipeJSON(jsonData: sampleJSON)
            #expect(recipe.name != nil)
            if let name = recipe.name {
                #expect(name == "Cupcakes")
            }
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

    @Test func testDecodeRecipeJSONMissingKey() {
        let missingKeyJSON = """
        {
            "@context": "https://schema.org/",
            "@type": "Recipe"
        }
        """.data(using: .utf8)!

        do {
            let recipe = try parser.decodeRecipeJSON(jsonData: missingKeyJSON)
            #expect(recipe.name == nil)
            #expect(recipe.recipeYield == nil)
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

}
