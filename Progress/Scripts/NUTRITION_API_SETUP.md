# Nutrition API Setup Guide

This guide will help you set up the USDA FoodData Central API for nutrition logging in the Progress app.

## Quick Start (Demo)

The app is currently configured with a `DEMO_KEY` which allows limited testing. For production use, you'll need to get a free API key.

## Getting a Free API Key

1. **Visit the USDA FoodData Central API Guide**
   - Go to: https://fdc.nal.usda.gov/api-guide.html
   - Click "Get an API Key"

2. **Register for a Free Account**
   - Fill out the simple registration form
   - You'll receive your API key instantly via email
   - **No cost** - the API is completely free

3. **Update the App Configuration**
   - Open `Progress/Core/Services/FoodSearchService.swift`
   - Replace `DEMO_KEY` with your actual API key:
   ```swift
   private let apiKey = "YOUR_API_KEY_HERE"
   ```

## API Features Available

With the free USDA FoodData Central API, you get access to:

- **300,000+ foods** from the USDA database
- **Verified nutrition data** from Foundation Foods
- **Branded foods database** with 1M+ products
- **Complete macro and micronutrient profiles**
- **No rate limits** for reasonable usage
- **100% free forever**

## Alternative APIs (Future Considerations)

For enhanced features, consider these APIs:

1. **Open Food Facts API** (Free)
   - Great for barcode scanning
   - International product database
   - Community-maintained

2. **Edamam Food Database API** (Freemium)
   - Natural language parsing
   - Recipe analysis
   - 900,000+ foods

3. **Spoonacular API** (Freemium)
   - Recipe suggestions
   - Meal planning
   - Ingredient substitutions

## Testing the Integration

1. Run the app in Xcode
2. Navigate to the Nutrition tab
3. Tap "Log First Meal"
4. Search for "chicken breast" or "banana"
5. You should see search results appear

## Troubleshooting

**No search results?**
- Check your internet connection
- Verify your API key is correct
- Try a different search term (e.g., "apple", "eggs")

**"Server error" messages?**
- Replace `DEMO_KEY` with your actual API key
- Ensure the API key is valid and active

**Need help?**
- Check the USDA API documentation: https://fdc.nal.usda.gov/api-guide.html
- API is very reliable with 99.9%+ uptime

## Implementation Notes

The current implementation:
- ✅ Searches foods by name
- ✅ Displays verified vs unverified foods
- ✅ Shows nutrition information per serving
- ✅ Supports quantity adjustments
- ✅ Logs to local database with CloudKit sync

**Next steps for enhancement:**
- Add barcode scanning with Open Food Facts API
- Implement natural language parsing ("2 cups of rice")
- Add favorite foods for quick logging
- Enable offline mode with cached foods