import JSONLDDecoder

public struct ParsedRecipe: Decodable {
    var name: String?
    
    @ArrayOfNestedObjectsDecoder<String, ImageCodingKeys>
    var images: [String]?
    
    @StringArrayDecoder
    var recipeYield: [String]?
    
    @NestedObjectsDecoder<String, AuthorCodingKeys>
    var author: String?
    
    @NestedObjectsDecoder<String, DescriptionCodingKeys>
    var description: String?
    
    var totalTime: String?
    var prepTime: String?
    var cookTime: String?
    
    @AdaptiveArrayDecoder
    var instructions: [ParsedInstruction]?
    
    @StringArrayDecoder
    var ingredients: [String]?
    
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
    
    enum ImageCodingKeys: String, CodingKey, CaseIterable {
        case url
    }
    
    enum AuthorCodingKeys: String, CodingKey, CaseIterable {
        case name
    }
    
    enum DescriptionCodingKeys: String, CodingKey, CaseIterable {
        case description
    }
    
}

public struct ParsedInstruction: Decodable, Equatable, NestedObjectProtocol {
    public let text: String?
    let name: String?
    let image: String?
    
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

