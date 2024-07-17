import Testing
import Foundation
import SwiftSoup
@testable import RecipeScraper

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

    @Test func testDecodeRecipeJSONFullModel() {
        let recipeJSON = """
        {
            "@context": "http://schema.org",
            "@type": "Recipe",
            "name": "Cupcakes",
            "image": [
                {
                  "@type": "ImageObject",
                  "url": "https://www.recipes.com/wp-content/uploads/2024/01/0117-296x180.jpg"
                }
            ],
            "recipeYield": "4 servings",
            "author": { "@type": "Person", "name": "John Apple" },
            "description": "Fluffy cupcakes",
            "prepTime": "PT900S",
            "cookTime": "PT1980S",
            "totalTime": "PT2880S",
            "recipeInstructions": [
                {
                    "@type": "HowToStep",
                    "text": "something",
                    "name": "something",
                    "url": "https://recipes.com/#step-1"
                },
                {
                    "@type": "HowToStep",
                    "text": "something2",
                    "name": "something3",
                    "url": "https://recipes.com/#step-2"
                },
                {
                    "@type": "HowToStep",
                    "text": "something4",
                    "name": "something5",
                    "url": "https://recipes.com/#step-3"
                }
            ],
        "recipeIngredient": [
            "1 large egg",
            "2 tablespoons milk",
            "1 teaspoon salt"
        ],
        }
        """.data(using: .utf8)!

        let parsedInstrunction = [
            ParsedInstruction(text: "something", name: "something", image: "https://recipes.com/#step-1"),
            ParsedInstruction(text: "something2", name: "something3", image: "https://recipes.com/#step-2"),
            ParsedInstruction(text: "something4", name: "something5", image: "https://recipes.com/#step-3"),
        ]

        do {
            let recipe = try parser.decodeRecipeJSON(jsonData: recipeJSON)
            #expect(recipe.name == "Cupcakes")
            #expect(recipe.recipeYield == ["4 servings"])
            #expect(recipe.images == ["https://www.recipes.com/wp-content/uploads/2024/01/0117-296x180.jpg"])
            #expect(recipe.author == "John Apple")
            #expect(recipe.description == "Fluffy cupcakes")
            #expect(recipe.prepTime == "PT900S")
            #expect(recipe.cookTime == "PT1980S")
            #expect(recipe.totalTime == "PT2880S")
            #expect(recipe.instructions == parsedInstrunction)
            #expect(recipe.ingredients == [
                "1 large egg",
                "2 tablespoons milk",
                "1 teaspoon salt"
            ])
        } catch {
            Issue.record("Decoding failed with error: \(error)")
        }
    }

}
