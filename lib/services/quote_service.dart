import 'dart:convert';
import 'package:http/http.dart' as http;
import 'cache_service.dart';
import 'api_service.dart';

class Quote {
  final String text;
  final String author;
  final String category;
  final List<String> tags;
  final String date;

  Quote({
    required this.text,
    required this.author,
    required this.category,
    required this.tags,
    required this.date,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      text: json['text'] ?? json['quote'] ?? '',
      author: json['author'] ?? 'Unknown',
      category: json['category'] ?? 'inspire',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      date: json['date'] ?? '',
    );
  }
}

class QuoteService {
  static const String _cacheKey = 'daily_quote';
  static const String _dismissedKey = 'daily_quote_dismissed_at';

  /// How long the quote card stays hidden after the user closes it (1 hour).
  static const Duration _dismissTtl = Duration(hours: 1);

  /// Returns "yyyy-MM-dd" for today.
  static String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Dismiss helpers ───────────────────────────────────────────────────────

  /// Call when the user taps the close button on the quote card.
  static Future<void> dismiss() async {
    await CacheService.setMap(_dismissedKey, {
      'dismissedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Returns true if the card should be hidden (dismissed less than 1 hour ago).
  static Future<bool> isDismissed() async {
    final data = await CacheService.getMap(_dismissedKey);
    if (data == null) return false;
    final raw = data['dismissedAt'] as String?;
    if (raw == null) return false;
    final dismissedAt = DateTime.tryParse(raw);
    if (dismissedAt == null) return false;
    return DateTime.now().difference(dismissedAt) < _dismissTtl;
  }

  // ── Quote fetching ────────────────────────────────────────────────────────

  /// Returns today's daily quote.
  /// Cache is keyed to the calendar date — changes automatically at midnight.
  static Future<Quote?> getDailyQuote() async {
    final today = _todayKey();

    // Return cached quote only if it was fetched TODAY
    final cached = await CacheService.getMap(_cacheKey);
    if (cached != null) {
      final cachedDate = cached['cachedDate'] as String?;
      if (cachedDate == today) {
        return Quote.fromJson(cached);
      }
    }

    // Date changed (or no cache) — fetch fresh quote for today
    return await _fetchAndCache();
  }

  /// Fetch a random quote for background rotation.
  /// Does NOT touch the daily cache key — only used for slide extras.
  static Future<Quote?> fetchRandomQuote() async {
    return await _fetchFromApi();
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  /// Fetch from API and save to the daily cache key with today's date.
  static Future<Quote?> _fetchAndCache() async {
    final quote = await _fetchFromApi();
    if (quote == null) return null;

    await CacheService.setMap(_cacheKey, {
      'text': quote.text,
      'author': quote.author,
      'category': quote.category,
      'tags': quote.tags,
      'date': quote.date,
      // Key by calendar date — cache becomes stale at midnight automatically
      'cachedDate': _todayKey(),
    });

    return quote;
  }

  /// Raw API call — returns a Quote or null, never writes to cache.
  static Future<Quote?> _fetchFromApi() async {
    try {
      final token = await ApiService.getToken();
      final url = Uri.parse('${ApiService.baseUrl}/api/public/daily-quote');
      final response = await http
          .get(url, headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Error', 408),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['quote'] != null) {
          return Quote.fromJson(data['quote']);
        }
      }
    } catch (e) {
      print('Error fetching quote: $e');
    }
    return null;
  }

  /// Get a quote from a specific category (no caching).
  static Future<Quote?> getQuoteByCategory(String category) async {
    try {
      final token = await ApiService.getToken();
      final url = Uri.parse(
          '${ApiService.baseUrl}/api/public/daily-quote?category=$category');
      final response = await http
          .get(url, headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          })
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => http.Response('Error', 408),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['quote'] != null) {
          return Quote.fromJson(data['quote']);
        }
      }
    } catch (e) {
      print('Error fetching quote by category: $e');
    }
    return null;
  }

  /// Clear all quote cache (daily quote + dismiss state).
  static Future<void> clearCache() async {
    await CacheService.delete(_cacheKey);
    await CacheService.delete(_dismissedKey);
  }
}
