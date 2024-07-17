import Testing
import Foundation
@testable import RecipeScraper


@Suite("RecipeScraperTests") struct RecipeScraperTests {

    @Test func testScrapeRecipeSuccess() async throws {
        let expectedRecipe = ParsedRecipe(name: "Test Recipe")
        let parserMock = RecipeParserMock(result: .success(expectedRecipe))
        let scraper = RecipeScraper(recipeParser: parserMock)

        do {
            let recipe = try await scraper.scrapeRecipe(from: "https://example.com/recipe")
            #expect(recipe.name == expectedRecipe.name)
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test func testScrapeRecipeFailure() async {
        let expectedError = RecipeParserError.scrapingError
        let parserMock = RecipeParserMock(result: .failure(expectedError))
        let scraper = RecipeScraper(recipeParser: parserMock)

        do {
            let _ = try await scraper.scrapeRecipe(from: "https://example.com/recipe")
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error as? RecipeParserError == expectedError)
        }
    }
}


