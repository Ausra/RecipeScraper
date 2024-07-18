import Foundation

public protocol RecipeParserProtocol: Sendable {
    func scrapeRecipe(from url: String) async throws -> ParsedRecipe
}

public struct RecipeScraper: Sendable {

    private let recipeParser: RecipeParserProtocol

    public init(recipeParser: RecipeParserProtocol = RecipeParser()) {
        self.recipeParser = recipeParser
    }

    public func scrapeRecipe(from url: String) async throws -> ParsedRecipe {
        return try await recipeParser.scrapeRecipe(from: url)
    }
}


