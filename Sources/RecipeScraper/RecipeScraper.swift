import Foundation

public protocol RecipeParserProtocol {
    func scrapeRecipe(from url: String) async throws -> ParsedRecipe
}

public struct RecipeScraper {

    private let recipeParser: RecipeParserProtocol

    public init(recipeParser: RecipeParserProtocol = RecipeParser()) {
        self.recipeParser = recipeParser
    }

    public func scrapeRecipe(from url: String) async throws -> ParsedRecipe {
        return try await recipeParser.scrapeRecipe(from: url)
    }
}


