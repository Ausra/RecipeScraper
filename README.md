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
        .package(url: "https://github.com/Ausra/RecipeScraper.git", from: "1.0.0")
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
import Foundation
import RecipeScraper

// Define an asynchronous function to scrape the recipe
func fetchRecipe(from urlString: String) async {
    let scraper = RecipeScraper()

    do {
        let parsedRecipe = try await scraper.scrapeRecipe(from: urlString)
        print("Recipe Name: \(parsedRecipe.name ?? "No name")")
        print("Ingredients: \(parsedRecipe.ingredients ?? [])")
        // Handle other properties as needed
    } catch {
        print("Failed to scrape recipe: \(error.localizedDescription)")
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

### ParsedInstruction Properties

Each `ParsedInstruction` object contains the following properties:

- `text`: The instruction text (`String`)
- `name`: The name of the instruction step (`String`)
- `image`: The URL of an image associated with the instruction (`String`)

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Dependecies

- [SwiftSoup](https://github.com/scinfu/SwiftSoup) for HTML parsing.
- [JSONLDDecoder](https://github.com/Ausra/JSONLDDecoder) for JSON-LD decoding.


