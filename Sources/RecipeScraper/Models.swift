import JSONLDDecoder

public struct ParsedRecipe: Decodable, Sendable {
    public var name: String?

    @ArrayOfNestedObjectsDecoder<String, ImageCodingKeys>
    public var images: [String]?

    @StringArrayDecoder
    public var recipeYield: [String]?

    @NestedObjectsDecoder<String, AuthorCodingKeys>
    public var author: String?

    @NestedObjectsDecoder<String, DescriptionCodingKeys>
    public var description: String?

    public var totalTime: String?
    public var prepTime: String?
    public var cookTime: String?

    @AdaptiveArrayDecoder
    public var instructions: [ParsedInstruction]?

    @StringArrayDecoder
    public var ingredients: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case images = "image"
        case recipeYield
        case author
        case description
        case totalTime
        case prepTime
        case cookTime
        case instructions = "recipeInstructions"
        case ingredients = "recipeIngredient"
    }
    
    public enum ImageCodingKeys: String, CodingKey, CaseIterable {
        case url
    }
    
    public enum AuthorCodingKeys: String, CodingKey, CaseIterable {
        case name
    }
    
    public enum DescriptionCodingKeys: String, CodingKey, CaseIterable {
        case description
    }
    
}

public struct ParsedInstruction: Decodable, Equatable, NestedObjectProtocol, Sendable {
    public let text: String?
    public let name: String?
    public let image: String?

    private enum CodingKeys: String, CodingKey {
        case name, text, image = "url"
    }
    init(text: String?, name: String? = nil, image: String? = nil) {
        self.text = text
        self.name = name
        self.image = image
    }
    
    public init(text: String?) {
        self.text = text
        self.name = nil
        self.image = nil
    }
}

struct RecipeType: Codable {
    let type: String?
    let name: String?

    enum CodingKeys: String, CodingKey {
        case type = "@type"
        case name
    }
}

struct Graph: Codable {
    let graph: [RecipeType]?

    enum CodingKeys: String, CodingKey {
        case graph = "@graph"
    }
}
