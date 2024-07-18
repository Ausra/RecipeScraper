import Foundation
import SwiftSoup
import JSONLDDecoder

public enum RecipeParserError: Error, Sendable {
    case dataLoaderError
    case invalidHTML
    case emptyHTML
    case htmlParsingError
    case noRecipeMetaDataError
    case JSONerror
    case scrapingError
}

public enum RecipeDecodingError: Error, Sendable {
    case dataCorrupted
    case decodingFailed(Error)
}

public struct RecipeParser: RecipeParserProtocol, Sendable {

    private let dataLoader: DataLoaderProtocol

    public init(dataLoader: DataLoaderProtocol = DataLoader()) {
        self.dataLoader = dataLoader
    }

    public func scrapeRecipe(from url: String) async throws -> ParsedRecipe {
        let parsedHTML = try await parseHTML(from: url)
        let parsedRecipeJSON = try parseRecipeJSON(from: parsedHTML)

        guard let json = parsedRecipeJSON else {
            throw RecipeParserError.scrapingError
        }
        let parsedRecipe = try decodeRecipeJSON(jsonData: json)
        return parsedRecipe
    }

    public func parseHTML(from url: String) async throws -> String {
        guard let data = try await dataLoader.loadData(from: url) else { throw RecipeParserError.dataLoaderError }
        let html = String(decoding: data, as: UTF8.self)

        return html
    }

    public func parseRecipeJSON(from html: String) throws -> Data? {
        do {
            let doc = try SwiftSoup.parse(html)
            let scriptElements = try doc.getElementsByAttributeValue("type", "application/ld+json")

            var recipeJSONString: String?
            let decoder = JSONDecoder()
            let encoder = JSONEncoder()

            for element in scriptElements {
                let elementData = element.data()
                if let jsonData = elementData.data(using: .utf8) {
                    do {
                        // Attempt to decode the JSON data into a RecipeType object
                        let recipe = try decoder.decode(RecipeType.self, from: jsonData)
                        if recipe.type?.lowercased() == "recipe" {
                            recipeJSONString = elementData
                            break
                        } else {
                            // If direct decoding to RecipeType fails, try decoding into a Graph object
                            let graph = try decoder.decode(Graph.self, from: jsonData)
                            if let recipes = graph.graph {
                                for item in recipes {
                                    if item.type?.lowercased() == "recipe" {
                                        let itemData = try encoder.encode(item)
                                        recipeJSONString = String(data: itemData, encoding: .utf8)
                                        break
                                    }
                                }
                            }
                        }
                    } catch {
                        // Throw a specific JSON decoding error
                        throw RecipeParserError.JSONerror
                    }
                }
                if recipeJSONString != nil {
                    break
                }
            }

            guard let recipeString = recipeJSONString, !recipeString.isEmpty else {
                throw RecipeParserError.noRecipeMetaDataError
            }

            guard let jsonData = recipeString.data(using: .utf8) else {
                throw RecipeParserError.htmlParsingError
            }

            return jsonData
        } catch let error as RecipeParserError {
            throw error
        } catch {
            throw RecipeParserError.invalidHTML
        }
    }

    public func decodeRecipeJSON(jsonData: Data) throws -> ParsedRecipe {
        let decoder = RecipeJSONLDDecoder()

        do {
            let parsedRecipe = try decoder.decode(ParsedRecipe.self, from: jsonData)
            return parsedRecipe
        } catch {
            throw RecipeDecodingError.decodingFailed(error)
        }
    }
}
