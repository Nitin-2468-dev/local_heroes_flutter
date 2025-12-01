import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to fetch images from Wikipedia pages
class WikipediaService {
  static const String _baseUrl = 'https://en.wikipedia.org/api/rest_v1/page/summary';
  
  /// Cache for fetched image URLs to avoid repeated API calls
  static final Map<String, String?> _imageCache = {};

  /// Extracts the Wikipedia page title from a wiki link
  /// e.g., 'https://en.wikipedia.org/wiki/A._P._J._Abdul_Kalam' -> 'A._P._J._Abdul_Kalam'
  static String? extractPageTitle(String? wikiLink) {
    if (wikiLink == null || wikiLink.isEmpty) return null;
    
    final uri = Uri.tryParse(wikiLink);
    if (uri == null) return null;
    
    final pathSegments = uri.pathSegments;
    if (pathSegments.length >= 2 && pathSegments[0] == 'wiki') {
      return pathSegments[1];
    }
    return null;
  }
  
  /// Get cached image URL if available
  static String? getCachedImageUrl(String wikiLink) {
    return _imageCache[wikiLink];
  }

  /// Fetches the main image URL from a Wikipedia page
  /// Returns null if no image is found or on error
  /// Uses caching to avoid repeated API calls
  static Future<String?> fetchImageUrl(String wikiLink, {int retries = 2}) async {
    // Check cache first
    if (_imageCache.containsKey(wikiLink)) {
      return _imageCache[wikiLink];
    }
    
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final pageTitle = extractPageTitle(wikiLink);
        if (pageTitle == null) return null;

        final url = '$_baseUrl/$pageTitle';
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'IconDeckIndia/1.0 (Flutter App)',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          // Try to get the original image first, then thumbnail
          final originalImage = data['originalimage']?['source'];
          if (originalImage != null) {
            _imageCache[wikiLink] = originalImage;
            return originalImage;
          }
          
          final thumbnail = data['thumbnail']?['source'];
          if (thumbnail != null) {
            _imageCache[wikiLink] = thumbnail;
            return thumbnail;
          }
          
          // No image found, cache null to prevent retries
          _imageCache[wikiLink] = null;
          return null;
        } else if (response.statusCode == 404) {
          // Page not found, cache null
          _imageCache[wikiLink] = null;
          return null;
        }
      } catch (e) {
        if (attempt == retries) {
          // Final attempt failed
          print('WikipediaService error for $wikiLink after ${retries + 1} attempts: $e');
        } else {
          // Wait before retry
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
    return null;
  }

  /// Fetches images for multiple wiki links in parallel (limited concurrency)
  static Future<Map<String, String?>> fetchMultipleImages(List<String> wikiLinks) async {
    final results = <String, String?>{};
    
    // Fetch in batches of 3 to avoid overwhelming the network
    for (int i = 0; i < wikiLinks.length; i += 3) {
      final batch = wikiLinks.skip(i).take(3).toList();
      final futures = batch.map((link) async {
        final imageUrl = await fetchImageUrl(link);
        return MapEntry(link, imageUrl);
      });
      
      final batchResults = await Future.wait(futures);
      results.addEntries(batchResults);
    }
    
    return results;
  }
  
  /// Clear the cache (useful for testing or refresh)
  static void clearCache() {
    _imageCache.clear();
  }
}
