# Festival Banner Feature

## Overview
This feature automatically displays festival banners on the home screen when it's a festival day. The banner appears above all cards and shows for the entire day.

## Real-Time Festival Date Feature

The festival service now supports **real-time festival date calculations** that automatically update every year. This ensures festival dates are always accurate without requiring manual updates.

### Key Features:

1. **Automatic Year-Based Calculations**: Festival dates are calculated dynamically for each year, accounting for:
   - Fixed-date festivals (same date every year)
   - Easter-based festivals (calculated using astronomical algorithms)
   - Lunar calendar festivals (simplified calculation, can be enhanced with API)

2. **Real-Time Updates**: The system automatically refreshes festival data:
   - On app startup via `FestivalService.initializeWithApi()`
   - Periodically (every 24 hours) via timer in home screen
   - When app resumes from background
   - When year changes automatically

3. **API Integration Ready**: Infrastructure for external API integration:
   - `FestivalApiService` provides structure for fetching dynamic festival dates
   - Caching mechanism to reduce API calls
   - Fallback to local calculations if API unavailable

4. **Accurate Easter Calculations**: Uses the `astronomia` package for precise Easter Sunday calculations, which automatically handles:
   - Good Friday (2 days before Easter)
   - Easter Sunday
   - Other Easter-related festivals

## How It Works

### 1. Festival Service (`lib/services/festival_service.dart`)
The festival service manages all festival data and date checking:
- Contains a list of pre-configured festivals with dates, messages, emojis, and gradient colors
- Automatically calculates festival dates for the current year
- Uses astronomical algorithms for Easter-based festivals
- Provides methods to get current festival and check if today is a festival
- Supports real-time updates via API integration
- Auto-refreshes when year changes

### 2. Festival API Service (`lib/services/festival_api_service.dart`)
Service for fetching dynamic festival dates from external APIs:
- Provides structure for API integration
- Implements caching to reduce API calls
- Falls back to local calculations if API unavailable
- Ready for production API integration

### 3. Festival Banner Widget (`lib/widgets/festival_banner.dart`)
A beautiful animated banner component that:
- Displays festival name, message, and emoji
- Uses gradient colors specific to each festival
- Has smooth fade and scale animations
- Includes a close button to dismiss the banner
- Automatically appears on festival days

### 4. Integration in Home Screen (`lib/screens/home/home_screen.dart`)
The banner is integrated into the home screen:
- Appears before the dashboard cards
- Shows only when it's a festival day
- Can be dismissed by the user
- Respects the app's theme
- Automatically updates festival dates every 24 hours
- Refreshes when app resumes from background

### 5. App Initialization (`lib/main.dart`)
The festival service is initialized during app startup:
- Calls `FestivalService.initializeWithApi()` on app launch
- Ensures festival dates are current when app starts
- Falls back to local calculations if API unavailable

## Festival Date Calculation Methods

### Fixed Date Festivals
These festivals occur on the same date every year:
- New Year (January 1)
- Republic Day (January 26)
- Valentine's Day (February 14)
- Christmas (December 25)
- And many more...

### Easter-Based Festivals
Calculated using the `astronomia` package for astronomical accuracy:
- **Easter Sunday**: Calculated using the official astronomical algorithm
- **Good Friday**: 2 days before Easter Sunday
- Automatically adjusts each year based on astronomical calculations

### Lunar Calendar Festivals
Currently use simplified calculations with API integration ready:
- Holi, Diwali, Eid, etc.
- Structure in place for proper lunar calendar library integration
- Can be enhanced with API-based date lookups
- Fallback to approximate dates if enhanced calculation unavailable

## Real-Time Update Mechanisms

### 1. App Startup
```dart
// In main.dart
await FestivalService.initializeWithApi();
```

### 2. Periodic Updates (24-hour timer)
```dart
// In home_screen.dart
_festivalUpdateTimer = Timer.periodic(
  const Duration(hours: 24),
  (_) async {
    await FestivalService.schedulePeriodicUpdates();
    if (mounted) {
      setState(() {
        _showFestivalBanner = FestivalService.isTodayFestival();
      });
    }
  },
);
```

### 3. App Resume
```dart
// In home_screen.dart didChangeAppLifecycleState
if (state == AppLifecycleState.resumed) {
  FestivalService.autoRefreshIfNeeded();
  setState(() {
    _showFestivalBanner = FestivalService.isTodayFestival();
  });
}
```

### 4. Year Change Detection
```dart
// Automatic year change detection
static bool needsRefresh() {
  final now = _testDate ?? DateTime.now();
  return _cachedYear != now.year;
}
```

## Configured Festivals

The following festivals are currently configured with real-time date calculations:

### Fixed Date Festivals
- New Year (January 1)
- Lohri (January 13)
- Makar Sankranti (January 14)
- Pongal (January 14)
- Republic Day (January 26)
- Valentine's Day (February 14)
- April Fools' Day (April 1)
- Baisakhi (April 13)
- Labor Day (May 1)
- Father's Day (June 15)
- Independence Day (August 15)
- Halloween (October 31)
- Christmas (December 25)
- New Year's Eve (December 31)

### Easter-Based Festivals (Real-time Calculation)
- Good Friday (2 days before Easter)
- Easter Sunday (calculated astronomically)

### Lunar Calendar Festivals (Ready for Enhancement)
- Vasant Panchami
- Mahashivratri
- Holi
- Ram Navami
- Eid ul-Fitr
- Ramadan
- Hanuman Jayanti
- Buddha Purnima
- Eid ul-Adha
- Raksha Bandhan
- Janmashtami
- Ganesh Chaturthi
- Onam
- Dussehra
- Karwa Chauth
- Diwali
- Govardhan Puja
- Bhai Dooj
- Chhath Puja

## Testing the Feature

### Testing with Different Dates
```dart
// Set a test date
FestivalService.setTestDate(DateTime(2026, 4, 5)); // Easter Sunday 2026

// Check if it works
print(FestivalService.isTodayFestival()); // true
print(FestivalService.getCurrentFestival()?.name); // Easter Sunday

// Reset to real date
FestivalService.clearTestDate();
```

### Testing Real-Time Updates
```dart
// Test year change detection
FestivalService.setTestDate(DateTime(2026, 12, 31));
FestivalService.autoRefreshIfNeeded();

// Change to next year
FestivalService.setTestDate(DateTime(2027, 1, 1));
final needsRefresh = FestivalService.needsRefresh();
print(needsRefresh); // true
```

### Running Tests
```bash
flutter test test/realtime_festival_test.dart
```

## API Integration Setup

To enable real-time API-based festival updates:

1. **Update FestivalApiService** with your API endpoint:
```dart
static const String _baseUrl = 'https://your-api.com/festivals';
```

2. **Implement the API call** in `fetchFestivalDates`:
```dart
final response = await http.get(
  Uri.parse('$_baseUrl/$year'),
  headers: {'Content-Type': 'application/json'},
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  _cachedData = data;
  _lastFetch = DateTime.now();
  return data;
}
```

3. **Parse API response** in `updateFestivalsFromApi` to update festival dates

## Customization

### Changing Banner Appearance
Edit `lib/widgets/festival_banner.dart` to customize:
- Animation duration and curves
- Banner size and padding
- Font sizes and styles
- Close button appearance

### Changing Festival Data
Edit `lib/services/festival_service.dart` to:
- Add/remove festivals
- Change messages
- Update colors
- Modify date calculation methods

### Adjusting Update Frequency
Change the timer duration in `home_screen.dart`:
```dart
_festivalUpdateTimer = Timer.periodic(
  const Duration(hours: 12), // Change to desired frequency
  (_) async { ... },
);
```

## Features

- ✅ Automatic date detection
- ✅ Real-time festival date calculations
- ✅ Year-based automatic updates
- ✅ Accurate Easter calculations
- ✅ API integration ready
- ✅ Beautiful gradient backgrounds
- ✅ Smooth animations
- ✅ Dismissible banner
- ✅ Festival-specific styling
- ✅ Theme-aware
- ✅ Close button functionality
- ✅ Appears before all cards
- ✅ Shows for entire day
- ✅ Periodic auto-refresh
- ✅ App resume detection
- ✅ Year change detection

## Technical Details

- **Service**: `FestivalService` handles all festival logic
- **API Service**: `FestivalApiService` provides API integration structure
- **Widget**: `FestivalBanner` provides the UI component
- **Integration**: Added to `HomeScreen` build method and lifecycle
- **State**: Uses `_showFestivalBanner` to control visibility
- **Performance**: Optimized with proper disposal of animation controllers
- **Accuracy**: Uses `astronomia` package for Easter calculations
- **Updates**: Timer-based and lifecycle-based refresh mechanisms

## Dependencies

- `astronomia: ^0.3.0` - For accurate Easter calculations
- `http: ^1.0.0` - For API integration (when implemented)
- `dart:convert` - For JSON parsing (when API implemented)

## Future Enhancements

Potential improvements:
- Complete API integration for all festival dates
- Add proper lunar calendar library (tithi_engine) for Hindu festivals
- Support for regional festivals
- Multi-language support for messages
- Festival countdown timer
- User preferences for festival notifications
- Custom festival creation by users
- Location-based festival variations
- Push notifications for upcoming festivals