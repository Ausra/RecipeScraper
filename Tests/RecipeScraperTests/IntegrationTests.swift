import Testing
import Foundation
@testable import RecipeScraper

@Suite("InegrationTests")
struct IntegrationTests {

    let htmlData = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Cupcake Recipe</title>
        </head>
        <body>
        <h1>Cupcakes</h1>
        <img src="https://www.recipes.com/wp-content/uploads/2024/01/0117-296x180.jpg" alt="Cupcakes">
        <p><strong>Yield:</strong> 4 servings</p>
        <p><strong>Author:</strong> John Apple</p>
        <p><strong>Description:</strong> Fluffy cupcakes</p>
        <p><strong>Prep Time:</strong> 15 minutes</p>
        <p><strong>Cook Time:</strong> 33 minutes</p>
        <p><strong>Total Time:</strong> 48 minutes</p>
    
        <h2>Ingredients</h2>
        <ul>
        <li>1 large egg</li>
        <li>2 tablespoons milk</li>
        <li>1 teaspoon salt</li>
        </ul>
    
        <h2>Instructions</h2>
        <ol>
        <li>
        <a href="https://recipes.com/#step-1">Step 1:</a> something
        </li>
        <li>
        <a href="https://recipes.com/#step-2">Step 2:</a> something2
        </li>
        <li>
        <a href="https://recipes.com/#step-3">Step 3:</a> something4
        </li>
        </ol>
    
        <script type="application/ld+json">
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
            ]
        }
        </script>
        </body>
        </html>
    """.data(using: .utf8)!


    @Test func fullIntegrationRecipeParser() async {

        let mockNetworking = NetworkingMock(result: .success(htmlData))
        let dataLoader = DataLoader(networking: mockNetworking)
        let urlString = "https://example.com"

        let parser = RecipeParser(dataLoader: dataLoader)

        let parsedInstrunction = [
            ParsedInstruction(text: "something", name: "something", image: "https://recipes.com/#step-1"),
            ParsedInstruction(text: "something2", name: "something3", image: "https://recipes.com/#step-2"),
            ParsedInstruction(text: "something4", name: "something5", image: "https://recipes.com/#step-3"),
        ]


        do {
            let recipe = try await parser.scrapeRecipe(from: urlString)
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
            Issue.record("Scraping failed with error: \(error)")
        }
    }

    @Test func fullIntegrationRecipeScraper() async {
        let parsedInstrunction = [
            ParsedInstruction(text: "something", name: "something", image: "https://recipes.com/#step-1"),
            ParsedInstruction(text: "something2", name: "something3", image: "https://recipes.com/#step-2"),
            ParsedInstruction(text: "something4", name: "something5", image: "https://recipes.com/#step-3"),
        ]

        let expectedRecipe = ParsedRecipe(
            name: "Cupcakes",
            images: ["https://www.recipes.com/wp-content/uploads/2024/01/0117-296x180.jpg"],
            recipeYield: ["4 servings"],
            author: "John Apple",
            description: "Fluffy cupcakes",
            totalTime: "PT2880S",
            prepTime: "PT900S",
            cookTime: "PT1980S",
            instructions: parsedInstrunction,
            ingredients: [
                "1 large egg",
                "2 tablespoons milk",
                "1 teaspoon salt"
            ]
        )
        let parserMock = RecipeParserMock(result: .success(expectedRecipe))
        let scraper = RecipeScraper(recipeParser: parserMock)

        do {
            let recipe = try await scraper.scrapeRecipe(from: "https://example.com/recipe")
            #expect(recipe != nil)
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
            Issue.record("Scraping failed with error: \(error)")
        }
    }
}
