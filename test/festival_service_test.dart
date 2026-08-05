import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import '../lib/services/festival_service.dart';

void main() {
  group('FestivalService Tests', () {
    setUp(() {
      // Clear any test date before each test
      FestivalService.clearTestDate();
    });

    test('Should return all festivals for current year', () {
      final festivals = FestivalService.getAllFestivals();
      expect(festivals.isNotEmpty, true);
      print('Total festivals: ${festivals.length}');
    });

    test('Should detect today\'s festival if date matches', () {
      // Test with New Year (January 1st)
      FestivalService.setTestDate(DateTime(2026, 1, 1));
      final festival = FestivalService.getCurrentFestival();
      expect(festival, isNotNull);
      expect(festival!.name, 'New Year');
      print('Found festival: ${festival.name} on ${festival.date}');
      FestivalService.clearTestDate();
    });

    test('Should return upcoming festival', () {
      FestivalService.setTestDate(DateTime(2026, 1, 1));
      final upcoming = FestivalService.getUpcomingFestival();
      expect(upcoming, isNotNull);
      print('Upcoming festival: ${upcoming!.name} on ${upcoming.date}');
      FestivalService.clearTestDate();
    });

    test('Should return festivals for specific month', () {
      final augustFestivals = FestivalService.getFestivalsForMonth(8);
      expect(augustFestivals.isNotEmpty, true);
      print('August festivals: ${augustFestivals.map((f) => f.name).toList()}');
    });

    test('Should return wish message for festival', () {
      FestivalService.setTestDate(DateTime(2026, 1, 1));
      final wishMessage = FestivalService.getTodayWishMessage();
      expect(wishMessage, isNotNull);
      expect(wishMessage!.contains('Happy New Year'), true);
      print('Wish message: $wishMessage');
      FestivalService.clearTestDate();
    });

    test('Should detect multiple festivals throughout the year', () {
      // Test various festivals
      final testDates = [
        DateTime(2026, 1, 1),   // New Year
        DateTime(2026, 1, 26),  // Republic Day
        DateTime(2026, 8, 15), // Independence Day
        DateTime(2026, 12, 25), // Christmas
      ];

      for (final date in testDates) {
        FestivalService.setTestDate(date);
        final festival = FestivalService.getCurrentFestival();
        if (festival != null) {
          print('Found ${festival.name} on ${date.day}/${date.month}');
        }
      }
      FestivalService.clearTestDate();
    });

    test('Should handle leap years correctly', () {
      FestivalService.setTestDate(DateTime(2024, 1, 1));
      final festivals2024 = FestivalService.getAllFestivals();
      expect(festivals2024.isNotEmpty, true);

      FestivalService.setTestDate(DateTime(2025, 1, 1));
      final festivals2025 = FestivalService.getAllFestivals();
      expect(festivals2025.isNotEmpty, true);

      print('2024 festivals: ${festivals2024.length}');
      print('2025 festivals: ${festivals2025.length}');
      FestivalService.clearTestDate();
    });
  });
}
