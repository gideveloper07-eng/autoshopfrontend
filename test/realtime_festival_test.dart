import 'package:flutter_test/flutter_test.dart';
import 'package:college_app/services/festival_service.dart';

void main() {
  test('Easter calculation should work for 2026', () {
    // Set test date to Easter 2026 (April 5)
    FestivalService.setTestDate(DateTime(2026, 4, 5));
    
    // Check if it's detected as Easter
    final festival = FestivalService.getCurrentFestival();
    expect(festival, isNotNull);
    expect(festival!.name, 'Easter Sunday');
    
    // Clear test date
    FestivalService.clearTestDate();
  });

  test('Good Friday should be 2 days before Easter', () {
    // Set test date to Good Friday 2026 (April 3)
    FestivalService.setTestDate(DateTime(2026, 4, 3));
    
    // Check if it's detected as Good Friday
    final festival = FestivalService.getCurrentFestival();
    expect(festival, isNotNull);
    expect(festival!.name, 'Good Friday');
    
    // Clear test date
    FestivalService.clearTestDate();
  });

  test('Real-time refresh should work when year changes', () {
    // Test with 2026
    FestivalService.setTestDate(DateTime(2026, 1, 1));
    final festivals2026 = FestivalService.getAllFestivals();
    expect(festivals2026.isNotEmpty, true);
    
    // Change to 2027
    FestivalService.setTestDate(DateTime(2027, 1, 1));
    final festivals2027 = FestivalService.getAllFestivals();
    expect(festivals2027.isNotEmpty, true);
    
    // Clear test date
    FestivalService.clearTestDate();
  });

  test('Auto-refresh should detect year change', () {
    // Start with 2026
    FestivalService.setTestDate(DateTime(2026, 12, 31));
    FestivalService.autoRefreshIfNeeded();
    
    // Change to 2027
    FestivalService.setTestDate(DateTime(2027, 1, 1));
    final needsRefresh = FestivalService.needsRefresh();
    expect(needsRefresh, true);
    
    // Clear test date
    FestivalService.clearTestDate();
  });
}