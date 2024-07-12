import JSONLDDecoder

public struct Recipe: Decodable {
    var name: String?
    @StringDecoder
    var recipeYield: [String]?
}
