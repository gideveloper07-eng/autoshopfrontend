import 'package:flutter/material.dart';
import '../services/festival_service.dart';
import '../widgets/festival_banner.dart';

/// Developer preview screen — shows how the FestivalBanner looks for every festival.
/// Accessible only in debug builds (or remove the assert to keep it in release).
class FestivalPreviewScreen extends StatefulWidget {
  const FestivalPreviewScreen({super.key});

  @override
  State<FestivalPreviewScreen> createState() => _FestivalPreviewScreenState();
}

class _FestivalPreviewScreenState extends State<FestivalPreviewScreen> {
  late List<Festival> _festivals;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load all festivals for the current year
    _festivals = FestivalService.getAllFestivals();
    _applyTestDate();
  }

  void _applyTestDate() {
    if (_festivals.isNotEmpty) {
      FestivalService.setTestDate(_festivals[_currentIndex].date);
    }
  }

  @override
  void dispose() {
    // Always clear the test date when leaving the preview
    FestivalService.clearTestDate();
    super.dispose();
  }

  void _prev() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _applyTestDate();
      });
    }
  }

  void _next() {
    if (_currentIndex < _festivals.length - 1) {
      setState(() {
        _currentIndex++;
        _applyTestDate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_festivals.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No festivals found.')),
      );
    }

    final festival = _festivals[_currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Festival Banner Preview'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              '${_currentIndex + 1} / ${_festivals.length}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Banner preview area ─────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  festival.gradientColors.first.withValues(alpha: 0.15),
                  Colors.white,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
            child: Column(
              children: [
                // Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: festival.gradientColors.first.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: festival.gradientColors.first.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Preview — how it appears in the app',
                    style: TextStyle(
                      fontSize: 11,
                      color: festival.gradientColors.first,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // The actual FestivalBanner widget
                FestivalBanner(
                  key: ValueKey(_currentIndex), // re-animate on each festival
                  onClose: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Close button tapped — banner dismissed in real app'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Festival details card ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailCard(
                    gradientColors: festival.gradientColors,
                    festival: festival,
                  ),
                  const SizedBox(height: 20),
                  // All festivals list
                  const Text(
                    'All Festivals',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._festivals.asMap().entries.map((entry) {
                    final i = entry.key;
                    final f = entry.value;
                    final isSelected = i == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _currentIndex = i;
                        _applyTestDate();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? f.gradientColors.first.withValues(alpha: 0.12)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? f.gradientColors.first
                                : Colors.grey.shade200,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(f.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f.name,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? f.gradientColors.first
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Text(
                              '${f.date.day}/${f.date.month}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Navigation controls ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0 ? _prev : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Previous'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _currentIndex < _festivals.length - 1 ? _next : null,
                  icon: const Text('Next'),
                  label: const Icon(Icons.chevron_right),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: festival.gradientColors.first,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail card ─────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final List<Color> gradientColors;
  final Festival festival;

  const _DetailCard({
    required this.gradientColors,
    required this.festival,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(festival.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      festival.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '${_monthName(festival.date.month)} ${festival.date.day}, ${festival.date.year}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (festival.wishMessage != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white30, height: 1),
            const SizedBox(height: 12),
            Text(
              festival.wishMessage!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _ColorDot(color: gradientColors[0]),
              const SizedBox(width: 4),
              if (gradientColors.length > 1) _ColorDot(color: gradientColors[1]),
              const SizedBox(width: 4),
              if (gradientColors.length > 2) _ColorDot(color: gradientColors[2]),
              const SizedBox(width: 8),
              Text(
                'Gradient colors',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 1),
      ),
    );
  }
}
