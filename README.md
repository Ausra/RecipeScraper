# RecipeScraper

RecipeScraper is a Swift package designed to scrape recipe data from web pages and return a parsed recipe struct with predefined propreties. It uses SwiftSoup package for HTML parsing and JSONLDDecoder for decoding JSON-LD structured data embedded within web pages.

## Features

- Asynchronous scraping of recipe data from web pages.
- Robust HTML parsing using SwiftSoup.
- JSON-LD decoding to extract structured recipe information.

## Requirements

- iOS 18.0+ / macOS 14.0+
- Swift 6.0+
- Xcode 16+
- swift-tools-version: 6.0

## Installation

### Using Swift Package Manager in Xcode

 1. Open your Xcode project.
 2. Choose `File > Add Package Dependencies` to open swift package manager.
 3. Enter the repository URL of the RecipeScraper package in the search field:
    ``` https://github.com/Ausra/RecipeScraper.git```
4. Click `Add Package` button
5. Xcode will fetch the package and add it to your project.


### Swift Package Manager

To add RecipeScraper to your project, include the following dependency in your `Package.swift` file:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YourApp",
    platforms: [
        .iOS(.v18),
    ],
    dependencies: [
        .package(url: "https://github.com/yourusername/RecipeScraper.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["RecipeScraper"]
        ),
    ]
)
```
## Usage

### Importing RecipeScraper

First, import RecipeScraper into your Swift file:

```swift
import RecipeScraper
```

### Scraping a Recipe

To scrape a recipe from a URL, create an instance of `RecipeScraper` and call its `scrapeRecipe(from:)` method. Here’s an example using SwiftUI:

```
import SwiftUI
import RecipeScraper

struct ContentView: View {
    @State private var urlString: String = ""
    @State private var recipe: ParsedRecipe?
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            TextField("Enter recipe URL", text: $urlString)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                Task {
                    await scrapeRecipe()
                }
            }) {
                Text("Scrape Recipe")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()

            if let recipe = recipe {
                displayRecipe(recipe)
            }

            if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }

    private func scrapeRecipe() async {
        let scraper = RecipeScraper()

        do {
            let scrapedRecipe = try await scraper.scrapeRecipe(from: urlString)
            DispatchQueue.main.async {
                self.recipe = scrapedRecipe
                self.errorMessage = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.recipe = nil
            }
        }
    }

    private func displayRecipe(_ recipe: ParsedRecipe) -> some View {
        VStack(alignment: .leading) {
            if let name = recipe.name {
                Text("Name: \(name)")
                    .font(.headline)
            }
            if let ingredients = recipe.ingredients {
                Text("Ingredients:")
                    .font(.subheadline)
                ForEach(ingredients, id: \.self) { ingredient in
                    Text(ingredient)
                }
            }
            if let instructions = recipe.instructions {
                Text("Instructions:")
                    .font(.subheadline)
                ForEach(instructions, id: \.self) { instruction in
                    Text(instruction)
                }
            }
        }
        .padding()
    }
}
```
### ParsedRecipe Properties
When you scrape a recipe using `RecipeParser`, it returns a `ParsedRecipe` struct with the following properties:

- `name`: The name of the recipe (`String`)
- `images`: An array of image URLs associated with the recipe (`[String]`)
- `recipeYield`: The yield of the recipe, typically the number of servings (`[String]`)
- `author`: The author of the recipe (`String`)
- `description`: A description of the recipe (`String`)
- `totalTime`: The total time required to prepare and cook the recipe (`String`formatted as an ISO 8601 duration, e.g., "PT1H" for 1 hour or "PT900S" for 15 minutes)
- `prepTime`: The time required to prepare the ingredients (`String`formatted as an ISO 8601 duration)
- `cookTime`: The time required to cook the recipe (`String` formatted as an ISO 8601 duration)
- `instructions`: An array of instructions for the recipe, each represented by a `ParsedInstruction` object (`[ParsedInstruction]`)
- `ingredients`: An array of ingredients required for the recipe (`[String]`)

### Example of ParsedRecipe
Here’s an example of what a parsed recipe might look like:

```
let parsedRecipe = ParsedRecipe(
    name: "Chocolate Cake",
    images: ["https://example.com/image1.jpg", "https://example.com/image2.jpg"],
    recipeYield: ["8 servings"],
    author: "John Doe",
    description: "A delicious chocolate cake",
    totalTime: "PT1H",
    prepTime: "PT15M",
    cookTime: "PT45M",
    instructions: [
        ParsedInstruction(text: "Preheat the oven to 350°F.", name: "Preheating the oven", url: "www.imagelinkfirst.com"),
        ParsedInstruction(text: "Mix the ingredients.", name: "Mixing the ingredients", url: "www.imagelinksecond.com"),
        ParsedInstruction(text: "Bake for 45 minutes.", name: "Baking", url: "www.imagelinkthird.com")
    ],
    ingredients: ["2 cups flour", "1 cup sugar", "1 cup cocoa powder"]
)
```
### ParsedInstruction Properties

Each `ParsedInstruction` object contains the following properties:

- `text`: The instruction text (`String`)
- `name`: The name of the instruction step (`String`)
- `image`: The URL of an image associated with the instruction (`String`)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgements

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) for HTML parsing.
- [JSONLDDecoder](https://github.com/Ausra/JSONLDDecoder) for JSON-LD decoding.


