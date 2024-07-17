import Foundation
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

struct RecipeParserMock: RecipeParserProtocol {
    var result: Result<ParsedRecipe, Error>?

    func scrapeRecipe(from url: String) async throws -> ParsedRecipe {
        return try result?.get() ?? ParsedRecipe()
    }
}
