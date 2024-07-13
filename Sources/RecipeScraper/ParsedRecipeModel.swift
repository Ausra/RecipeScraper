import JSONLDDecoder

public struct Recipe: Decodable {
    var name: String?
    
    @StringArrayDecoder
    var recipeYield: [String]?

}
