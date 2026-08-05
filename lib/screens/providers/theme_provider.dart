import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Theme schedule modes ──────────────────────────────────────────────────────
enum ThemeScheduleMode {
  manual, // user toggles manually
  auto,   // follows sunrise / sunset times
}

class ThemeProvider extends ChangeNotifier {
  static const String _keyMode        = 'app_theme_mode';
  static const String _keySchedule    = 'app_theme_schedule';
  static const String _keySunriseHour = 'app_sunrise_hour';
  static const String _keySunriseMin  = 'app_sunrise_min';
  static const String _keySunsetHour  = 'app_sunset_hour';
  static const String _keySunsetMin   = 'app_sunset_min';

  ThemeMode          _themeMode    = ThemeMode.light;
  ThemeScheduleMode  _scheduleMode = ThemeScheduleMode.manual;

  // Default sunrise = 06:00, sunset = 18:30
  TimeOfDay _sunriseTime = const TimeOfDay(hour: 6,  minute: 0);
  TimeOfDay _sunsetTime  = const TimeOfDay(hour: 18, minute: 30);

  Timer? _autoTimer;

  // ── Getters ────────────────────────────────────────────────────────────────
  ThemeMode         get themeMode    => _themeMode;
  ThemeScheduleMode get scheduleMode => _scheduleMode;
  TimeOfDay         get sunriseTime  => _sunriseTime;
  TimeOfDay         get sunsetTime   => _sunsetTime;
  bool              get isDark       => _themeMode == ThemeMode.dark;
  bool              get isAuto       => _scheduleMode == ThemeScheduleMode.auto;

  ThemeProvider() {
    _loadSavedPreferences();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Schedule mode
      final scheduleStr = prefs.getString(_keySchedule);
      if (scheduleStr == 'auto') {
        _scheduleMode = ThemeScheduleMode.auto;
      }

      // Sunrise / sunset times
      _sunriseTime = TimeOfDay(
        hour:   prefs.getInt(_keySunriseHour) ?? 6,
        minute: prefs.getInt(_keySunriseMin)  ?? 0,
      );
      _sunsetTime = TimeOfDay(
        hour:   prefs.getInt(_keySunsetHour) ?? 18,
        minute: prefs.getInt(_keySunsetMin)  ?? 30,
      );

      if (_scheduleMode == ThemeScheduleMode.auto) {
        // Apply immediately then start timer — don't restore manual saved mode
        _applyAutoTheme();
        _startAutoTimer();
      } else {
        // Restore manually saved theme
        final saved = prefs.getString(_keyMode);
        if (saved == 'dark') _themeMode = ThemeMode.dark;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('ThemeProvider: error loading prefs: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keySchedule,
          _scheduleMode == ThemeScheduleMode.auto ? 'auto' : 'manual');
      await prefs.setString(_keyMode, _themeMode == ThemeMode.dark ? 'dark' : 'light');
      await prefs.setInt(_keySunriseHour, _sunriseTime.hour);
      await prefs.setInt(_keySunriseMin,  _sunriseTime.minute);
      await prefs.setInt(_keySunsetHour,  _sunsetTime.hour);
      await prefs.setInt(_keySunsetMin,   _sunsetTime.minute);
    } catch (e) {
      debugPrint('ThemeProvider: error saving prefs: $e');
    }
  }

  // ── Auto theme logic ───────────────────────────────────────────────────────

  /// Returns true if the current time is between sunrise and sunset (= daytime).
  bool _isDaytime() {
    final now     = TimeOfDay.now();
    final nowMins = now.hour * 60 + now.minute;
    final sunriseMins = _sunriseTime.hour * 60 + _sunriseTime.minute;
    final sunsetMins  = _sunsetTime.hour  * 60 + _sunsetTime.minute;
    return nowMins >= sunriseMins && nowMins < sunsetMins;
  }

  void _applyAutoTheme() {
    final shouldBeLight = _isDaytime();
    final newMode = shouldBeLight ? ThemeMode.light : ThemeMode.dark;
    if (_themeMode != newMode) {
      _themeMode = newMode;
      notifyListeners();
    }
  }

  void _startAutoTimer() {
    _autoTimer?.cancel();
    // Check every minute for sunrise/sunset transitions
    _autoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_scheduleMode == ThemeScheduleMode.auto) {
        _applyAutoTheme();
      }
    });
  }

  void _stopAutoTimer() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Toggle between light / dark manually. Also switches schedule to manual.
  Future<void> toggleTheme() async {
    _scheduleMode = ThemeScheduleMode.manual;
    _stopAutoTimer();
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    await _savePreferences();
  }

  /// Set a specific theme mode manually.
  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode && _scheduleMode == ThemeScheduleMode.manual) return;
    _scheduleMode = ThemeScheduleMode.manual;
    _stopAutoTimer();
    _themeMode = mode;
    notifyListeners();
    await _savePreferences();
  }

  /// Enable / disable the auto sunrise-sunset schedule.
  Future<void> setScheduleMode(ThemeScheduleMode mode) async {
    if (_scheduleMode == mode) return;
    _scheduleMode = mode;
    if (mode == ThemeScheduleMode.auto) {
      _applyAutoTheme();
      _startAutoTimer();
    } else {
      _stopAutoTimer();
    }
    notifyListeners();
    await _savePreferences();
  }

  /// Update sunrise time (only meaningful when schedule = auto).
  Future<void> setSunriseTime(TimeOfDay time) async {
    _sunriseTime = time;
    if (_scheduleMode == ThemeScheduleMode.auto) _applyAutoTheme();
    notifyListeners();
    await _savePreferences();
  }

  /// Update sunset time (only meaningful when schedule = auto).
  Future<void> setSunsetTime(TimeOfDay time) async {
    _sunsetTime = time;
    if (_scheduleMode == ThemeScheduleMode.auto) _applyAutoTheme();
    notifyListeners();
    await _savePreferences();
  }

  /// Human-readable label for the current auto status.
  String get autoStatusLabel {
    if (_scheduleMode == ThemeScheduleMode.manual) return 'Manual';
    return _isDaytime() ? 'Day (Light)' : 'Night (Dark)';
  }

  String _fmt(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get sunriseLabel => _fmt(_sunriseTime);
  String get sunsetLabel  => _fmt(_sunsetTime);
}
