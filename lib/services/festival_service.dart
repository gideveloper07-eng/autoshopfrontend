import 'package:flutter/material.dart';
import 'package:tithi_engine/tithi_engine.dart' as te;
import 'package:tithi_engine/data/india.dart';
import 'package:astronomia/easter.dart' as astronomia;

class Festival {
  final String name;
  final String emoji;
  final DateTime date;
  final List<Color> gradientColors;
  final String? wishMessage;

  Festival({
    required this.name,
    required this.emoji,
    required this.date,
    required this.gradientColors,
    this.wishMessage,
  });
}

/// How each festival's date is determined.
enum _DateType {
  fixed,          // same Gregorian date every year (e.g. Jan 26)
  tithi,          // calculated from Hindu lunar calendar via tithi_engine
  easterRelative, // calculated relative to Easter
}

/// Blueprint for a festival.
class _FestivalBlueprint {
  final String name;
  final String emoji;
  final _DateType dateType;
  final List<Color> gradientColors;
  final String wishMessage;

  // For fixed festivals
  final int? fixedMonth;
  final int? fixedDay;

  // For tithi festivals — maps to the tithi_engine [festivals] list by id
  final String? tithiId;

  // For easter-relative festivals
  final int? easterOffsetDays; // e.g. -2 for Good Friday

  const _FestivalBlueprint({
    required this.name,
    required this.emoji,
    required this.dateType,
    required this.gradientColors,
    required this.wishMessage,
    this.fixedMonth,
    this.fixedDay,
    this.tithiId,
    this.easterOffsetDays,
  });
}

class FestivalService {
  // Test date override (null = use DateTime.now())
  static DateTime? _testDate;

  // Singleton Panchang — initialised once, reused for all years
  static te.Panchang? _panchang;

  static te.Panchang get _engine {
    _panchang ??= te.Panchang([registerIndia]);
    return _panchang!;
  }

  // ── Festival catalogue ────────────────────────────────────────────────────
  // tithi festivals reference ids from tithi_engine's built-in [festivals] list.
  // For festivals not in tithi_engine we fall back to Drik-Panchang rules
  // implemented inline in _resolveTithiDate().
  static const List<_FestivalBlueprint> _blueprints = [
    // ── January ──────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'New Year',
      emoji: '🎉',
      dateType: _DateType.fixed,
      fixedMonth: 1, fixedDay: 1,
      gradientColors: [Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7)],
      wishMessage: 'Happy New Year! Wishing you joy and prosperity!',
    ),
    _FestivalBlueprint(
      name: 'Lohri',
      emoji: '🔥',
      dateType: _DateType.fixed,
      fixedMonth: 1, fixedDay: 13,
      gradientColors: [Color(0xFFFF6B35), Color(0xFFF7C59F), Color(0xFFEFEFD0)],
      wishMessage: 'Happy Lohri! May this harvest festival bring you warmth and happiness!',
    ),
    _FestivalBlueprint(
      name: 'Makar Sankranti',
      emoji: '🪁',
      dateType: _DateType.fixed,
      fixedMonth: 1, fixedDay: 14,
      gradientColors: [Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722)],
      wishMessage: 'Happy Makar Sankranti! May your life soar high like kites!',
    ),
    _FestivalBlueprint(
      name: 'Pongal',
      emoji: '🌾',
      dateType: _DateType.fixed,
      fixedMonth: 1, fixedDay: 14,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)],
      wishMessage: 'Happy Pongal! May this harvest festival bring prosperity!',
    ),
    _FestivalBlueprint(
      name: 'Republic Day',
      emoji: '🇮🇳',
      dateType: _DateType.fixed,
      fixedMonth: 1, fixedDay: 26,
      gradientColors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
      wishMessage: 'Happy Republic Day! Jai Hind!',
    ),

    // ── February ─────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Vasant Panchami',
      emoji: '🌸',
      dateType: _DateType.tithi,
      tithiId: 'vasant_panchami', // resolved inline
      gradientColors: [Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800)],
      wishMessage: 'Happy Vasant Panchami! May knowledge blossom in your life!',
    ),
    _FestivalBlueprint(
      name: "Valentine's Day",
      emoji: '❤️',
      dateType: _DateType.fixed,
      fixedMonth: 2, fixedDay: 14,
      gradientColors: [Color(0xFFE91E63), Color(0xFFF44336), Color(0xFFFF5722)],
      wishMessage: "Happy Valentine's Day! Spread love and kindness!",
    ),
    _FestivalBlueprint(
      name: 'Mahashivratri',
      emoji: '🔱',
      dateType: _DateType.tithi,
      tithiId: 'maha_shivaratri',
      gradientColors: [Color(0xFF3F51B5), Color(0xFF673AB7), Color(0xFF9C27B0)],
      wishMessage: 'Happy Mahashivratri! May Lord Shiva bless you!',
    ),

    // ── March ─────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Holika Dahan',
      emoji: '🔥',
      dateType: _DateType.tithi,
      tithiId: 'holika_dahan', // resolved inline
      gradientColors: [Color(0xFFFF5733), Color(0xFFFFC300), Color(0xFFDAF7A6)],
      wishMessage: 'Happy Holika Dahan! May evil be burned away!',
    ),
    _FestivalBlueprint(
      name: 'Holi',
      emoji: '🎨',
      dateType: _DateType.tithi,
      tithiId: 'holi',
      gradientColors: [Color(0xFFFF5733), Color(0xFFFFC300), Color(0xFFDAF7A6)],
      wishMessage: 'Happy Holi! May your life be colorful and joyful!',
    ),
    _FestivalBlueprint(
      name: 'Ram Navami',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'ram_navami',
      gradientColors: [Color(0xFFFF9933), Color(0xFFFF5722), Color(0xFFE65100)],
      wishMessage: 'Happy Ram Navami! May Lord Ram bless you with strength!',
    ),

    // ── April ─────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: "April Fools' Day",
      emoji: '😄',
      dateType: _DateType.fixed,
      fixedMonth: 4, fixedDay: 1,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)],
      wishMessage: "Happy April Fools' Day! Keep smiling!",
    ),
    _FestivalBlueprint(
      name: 'Hanuman Jayanti',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'hanuman_jayanti', // resolved inline
      gradientColors: [Color(0xFFFF6B35), Color(0xFFF7C59F), Color(0xFFEFEFD0)],
      wishMessage: 'Happy Hanuman Jayanti! May you find strength and devotion!',
    ),
    _FestivalBlueprint(
      name: 'Good Friday',
      emoji: '✝️',
      dateType: _DateType.easterRelative,
      easterOffsetDays: -2,
      gradientColors: [Color(0xFF5D4037), Color(0xFF795548), Color(0xFF8D6E63)],
      wishMessage: 'May the blessings of Good Friday be with you!',
    ),
    _FestivalBlueprint(
      name: 'Easter Sunday',
      emoji: '🐰',
      dateType: _DateType.easterRelative,
      easterOffsetDays: 0,
      gradientColors: [Color(0xFFE91E63), Color(0xFFF44336), Color(0xFFFFC107)],
      wishMessage: 'Happy Easter! May you find joy and renewal!',
    ),
    _FestivalBlueprint(
      name: 'Baisakhi',
      emoji: '🌾',
      dateType: _DateType.fixed,
      fixedMonth: 4, fixedDay: 13,
      gradientColors: [Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800)],
      wishMessage: 'Happy Baisakhi! May this harvest festival bring prosperity!',
    ),

    // ── May ───────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Labour Day',
      emoji: '👷',
      dateType: _DateType.fixed,
      fixedMonth: 5, fixedDay: 1,
      gradientColors: [Color(0xFF607D8B), Color(0xFF90A4AE), Color(0xFFB0BEC5)],
      wishMessage: 'Happy Labour Day! Honouring the hard work of everyone!',
    ),
    _FestivalBlueprint(
      name: 'Buddha Purnima',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'buddha_purnima', // resolved inline
      gradientColors: [Color(0xFFFFEB3B), Color(0xFFFFC107), Color(0xFFFF9800)],
      wishMessage: 'Happy Buddha Purnima! May peace and wisdom be with you!',
    ),

    // ── June ──────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: "Father's Day",
      emoji: '👨',
      dateType: _DateType.fixed,
      fixedMonth: 6, fixedDay: 15,
      gradientColors: [Color(0xFF2196F3), Color(0xFF03A9F4), Color(0xFF00BCD4)],
      wishMessage: "Happy Father's Day! Thank you for everything!",
    ),

    // ── July ──────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Guru Purnima',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'guru_purnima',
      gradientColors: [Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFFF5722)],
      wishMessage: 'Happy Guru Purnima! Honour your teachers and mentors!',
    ),

    // ── August ────────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Friendship Day',
      emoji: '🤝',
      dateType: _DateType.fixed,
      fixedMonth: 8, fixedDay: 3,
      gradientColors: [Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7)],
      wishMessage: 'Happy Friendship Day! Cherish your friends!',
    ),
    _FestivalBlueprint(
      name: 'Independence Day',
      emoji: '🇮🇳',
      dateType: _DateType.fixed,
      fixedMonth: 8, fixedDay: 15,
      gradientColors: [Color(0xFFFF9933), Color(0xFFFFFFFF), Color(0xFF138808)],
      wishMessage: 'Happy Independence Day! Jai Hind!',
    ),
    _FestivalBlueprint(
      name: 'Raksha Bandhan',
      emoji: '🎀',
      dateType: _DateType.tithi,
      tithiId: 'raksha_bandhan',
      gradientColors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
      wishMessage: 'Happy Raksha Bandhan! Celebrating the bond of love!',
    ),
    _FestivalBlueprint(
      name: 'Janmashtami',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'janmashtami_smarta',
      gradientColors: [Color(0xFF2196F3), Color(0xFF03A9F4), Color(0xFF00BCD4)],
      wishMessage: 'Happy Janmashtami! May Lord Krishna bless you!',
    ),
    _FestivalBlueprint(
      name: 'Onam',
      emoji: '🌺',
      dateType: _DateType.tithi,
      tithiId: 'onam', // resolved inline
      gradientColors: [Color(0xFF9C27B0), Color(0xFFE91E63), Color(0xFFFF6B35)],
      wishMessage: 'Happy Onam! May prosperity fill your life!',
    ),

    // ── September ─────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: "Teachers' Day",
      emoji: '📚',
      dateType: _DateType.fixed,
      fixedMonth: 9, fixedDay: 5,
      gradientColors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)],
      wishMessage: "Happy Teachers' Day! Thank you for guiding us!",
    ),
    _FestivalBlueprint(
      name: 'Ganesh Chaturthi',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'ganesh_chaturthi',
      gradientColors: [Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7)],
      wishMessage: 'Happy Ganesh Chaturthi! May Lord Ganesha remove obstacles!',
    ),

    // ── October ───────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Gandhi Jayanti',
      emoji: '🕊️',
      dateType: _DateType.fixed,
      fixedMonth: 10, fixedDay: 2,
      gradientColors: [Color(0xFF8D6E63), Color(0xFFA1887F), Color(0xFFBCAAA4)],
      wishMessage: 'Gandhi Jayanti! Honouring the Father of the Nation!',
    ),
    _FestivalBlueprint(
      name: 'Navratri',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'sharad_navratri',
      gradientColors: [Color(0xFFFF9933), Color(0xFFFF5722), Color(0xFFE65100)],
      wishMessage: 'Happy Navratri! May Maa Durga bless you!',
    ),
    _FestivalBlueprint(
      name: 'Dussehra',
      emoji: '⚔️',
      dateType: _DateType.tithi,
      tithiId: 'vijayadashami',
      gradientColors: [Color(0xFFD32F2F), Color(0xFFFF6B35), Color(0xFFFFA726)],
      wishMessage: 'Happy Dussehra! Victory of good over evil!',
    ),
    _FestivalBlueprint(
      name: 'Karwa Chauth',
      emoji: '🌙',
      dateType: _DateType.tithi,
      tithiId: 'karva_chauth',
      gradientColors: [Color(0xFFE91E63), Color(0xFFF44336), Color(0xFFFF5722)],
      wishMessage: 'Happy Karwa Chauth! May the bond of love grow stronger!',
    ),
    _FestivalBlueprint(
      name: 'Halloween',
      emoji: '🎃',
      dateType: _DateType.fixed,
      fixedMonth: 10, fixedDay: 31,
      gradientColors: [Color(0xFF424242), Color(0xFF616161), Color(0xFF757575)],
      wishMessage: 'Happy Halloween! Have a spooktacular day!',
    ),

    // ── November ──────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Diwali',
      emoji: '🪔',
      dateType: _DateType.tithi,
      tithiId: 'diwali',
      gradientColors: [Color(0xFFFF6B35), Color(0xFFF7C59F), Color(0xFFEFEFD0)],
      wishMessage: 'Happy Diwali! May light overcome darkness!',
    ),
    _FestivalBlueprint(
      name: 'Govardhan Puja',
      emoji: '🙏',
      dateType: _DateType.tithi,
      tithiId: 'govardhan_puja', // resolved inline
      gradientColors: [Color(0xFF4CAF50), Color(0xFF8BC34A), Color(0xFFCDDC39)],
      wishMessage: 'Happy Govardhan Puja! May nature bless you!',
    ),
    _FestivalBlueprint(
      name: 'Bhai Dooj',
      emoji: '🎀',
      dateType: _DateType.tithi,
      tithiId: 'bhai_dooj',
      gradientColors: [Color(0xFFFF69B4), Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
      wishMessage: 'Happy Bhai Dooj! Celebrating the sibling bond!',
    ),
    _FestivalBlueprint(
      name: "Children's Day",
      emoji: '👶',
      dateType: _DateType.fixed,
      fixedMonth: 11, fixedDay: 14,
      gradientColors: [Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7)],
      wishMessage: "Happy Children's Day! Celebrating the future!",
    ),

    // ── December ──────────────────────────────────────────────────────────────
    _FestivalBlueprint(
      name: 'Christmas',
      emoji: '🎄',
      dateType: _DateType.fixed,
      fixedMonth: 12, fixedDay: 25,
      gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50), Color(0xFF8BC34A)],
      wishMessage: 'Merry Christmas! May peace and joy be with you!',
    ),
    _FestivalBlueprint(
      name: "New Year's Eve",
      emoji: '🎊',
      dateType: _DateType.fixed,
      fixedMonth: 12, fixedDay: 31,
      gradientColors: [Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF673AB7)],
      wishMessage: "Happy New Year's Eve! Get ready for new beginnings!",
    ),
  ];

  // ── Cache ─────────────────────────────────────────────────────────────────
  static List<Festival>? _cachedFestivals;
  static int? _cachedYear;

  // ── Date resolution ───────────────────────────────────────────────────────

  /// Resolve a tithi-based date using tithi_engine.
  /// For festival ids in the engine's own list we call [Panchang.dateFor].
  /// For the rest we use [Panchang.findDate] with the appropriate tithi spec.
  static DateTime? _resolveTithiDate(String tithiId, int year) {
    final engine = _engine;

    // First try the built-in festival list
    final builtIn = te.festivals.where((f) => f.id == tithiId).toList();
    if (builtIn.isNotEmpty) {
      final fd = engine.dateFor(builtIn.first, year, te.City.ujjain);
      return fd?.date;
    }

    // Festivals not in tithi_engine's list — defined by their tithi spec
    switch (tithiId) {
      case 'vasant_panchami':
        // Magha Shukla Panchami (5)
        return engine.findDate(te.LunarMonth.magha, te.Tithi.shukla(5), year, te.City.ujjain);

      case 'holika_dahan':
        // Phalguna Shukla Chaturdashi (14) — eve of Holi
        return engine.findDate(te.LunarMonth.phalguna, te.Tithi.shukla(14), year, te.City.ujjain);

      case 'hanuman_jayanti':
        // Chaitra Shukla Purnima (15)
        return engine.findDate(te.LunarMonth.chaitra, te.Tithi.shukla(15), year, te.City.ujjain);

      case 'buddha_purnima':
        // Vaishakha Shukla Purnima (15)
        return engine.findDate(te.LunarMonth.vaishakha, te.Tithi.shukla(15), year, te.City.ujjain);

      case 'onam':
        // Bhadrapada Shukla Tritiya (3) — closest tithi anchor for Thiruonam
        return engine.findDate(te.LunarMonth.bhadrapada, te.Tithi.shukla(3), year, te.City.ujjain);

      case 'govardhan_puja':
        // Kartika Shukla Pratipada (1)
        return engine.findDate(te.LunarMonth.kartika, te.Tithi.shukla(1), year, te.City.ujjain);

      default:
        return null;
    }
  }

  /// Resolve Easter for a given year using the astronomia package.
  static DateTime _easterDate(int year) {
    final e = astronomia.gregorian(year);
    return DateTime(year, e.month, e.day);
  }

  /// Build the full festival list for [year].
  static List<Festival> _calculateFestivalsForYear(int year) {
    final festivals = <Festival>[];

    for (final bp in _blueprints) {
      DateTime? date;

      switch (bp.dateType) {
        case _DateType.fixed:
          date = DateTime(year, bp.fixedMonth!, bp.fixedDay!);
          break;

        case _DateType.tithi:
          try {
            date = _resolveTithiDate(bp.tithiId!, year);
          } catch (_) {
            date = null;
          }
          break;

        case _DateType.easterRelative:
          try {
            final easter = _easterDate(year);
            date = easter.add(Duration(days: bp.easterOffsetDays!));
          } catch (_) {
            date = null;
          }
          break;
      }

      if (date != null) {
        festivals.add(Festival(
          name: bp.name,
          emoji: bp.emoji,
          date: date,
          gradientColors: bp.gradientColors,
          wishMessage: bp.wishMessage,
        ));
      }
    }

    festivals.sort((a, b) => a.date.compareTo(b.date));
    return festivals;
  }

  // ── Internal accessor ─────────────────────────────────────────────────────

  static List<Festival> _getFestivals() {
    final now = _testDate ?? DateTime.now();
    final year = now.year;

    if (_cachedFestivals != null && _cachedYear == year) {
      return _cachedFestivals!;
    }

    _cachedFestivals = _calculateFestivalsForYear(year);
    _cachedYear = year;
    return _cachedFestivals!;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// All festivals for the current year, sorted chronologically.
  static List<Festival> getAllFestivals() => List.from(_getFestivals());

  /// Today's festival if the date matches, otherwise null.
  static Festival? getCurrentFestival() {
    final now = _testDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final f in _getFestivals()) {
      final fd = DateTime(f.date.year, f.date.month, f.date.day);
      if (today == fd) return f;
    }
    return null;
  }

  /// Next festival from today (inclusive).
  static Festival? getUpcomingFestival() {
    final now = _testDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final f in _getFestivals()) {
      final fd = DateTime(f.date.year, f.date.month, f.date.day);
      if (!fd.isBefore(today)) return f;
    }
    return _getFestivals().isNotEmpty ? _getFestivals().first : null;
  }

  static bool isTodayFestival() => getCurrentFestival() != null;

  static List<Festival> getFestivalsForMonth(int month) =>
      _getFestivals().where((f) => f.date.month == month).toList();

  static List<Festival> getFestivalsInRange(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return _getFestivals().where((f) {
      final fd = DateTime(f.date.year, f.date.month, f.date.day);
      return !fd.isBefore(s) && !fd.isAfter(e);
    }).toList();
  }

  static String? getTodayWishMessage() => getCurrentFestival()?.wishMessage;

  static String? getWishMessageForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final f in _getFestivals()) {
      final fd = DateTime(f.date.year, f.date.month, f.date.day);
      if (target == fd) return f.wishMessage;
    }
    return null;
  }

  /// Force recalculation (call when year changes or for testing).
  static void refreshFestivals() {
    _cachedFestivals = null;
    _cachedYear = null;
  }

  static bool needsRefresh() {
    final now = _testDate ?? DateTime.now();
    return _cachedYear != now.year;
  }

  static void autoRefreshIfNeeded() {
    if (needsRefresh()) refreshFestivals();
  }

  // ── Test helpers ──────────────────────────────────────────────────────────

  static void setTestDate(DateTime? date) {
    _testDate = date;
    refreshFestivals();
  }

  static DateTime? getTestDate() => _testDate;

  static void clearTestDate() {
    _testDate = null;
    refreshFestivals();
  }

  // ── Legacy stubs (kept so existing callers don't break) ───────────────────

  static Future<void> initializeWithApi() async {}
  static Future<void> schedulePeriodicUpdates() async {}
  static String getDataSource() => 'tithi_engine';
}
