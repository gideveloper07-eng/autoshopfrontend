import 'dart:async';
import 'package:flutter/material.dart';
import '../services/quote_service.dart';
import '../theme/app_colors.dart';

class DailyQuoteWidget extends StatefulWidget {
  final VoidCallback? onClose;

  const DailyQuoteWidget({super.key, this.onClose});

  @override
  State<DailyQuoteWidget> createState() => _DailyQuoteWidgetState();
}

class _DailyQuoteWidgetState extends State<DailyQuoteWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _slideController;
  late Animation<Offset> _slideIn;
  late Animation<double> _fadeAnim;

  final List<Quote> _quotes = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  Timer? _autoSlideTimer;

  // Track the date the quotes were loaded for — reset when date changes
  String _loadedForDate = '';

  static const int _fetchCount = 5;

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeIn),
    );

    _loadQuotes();
  }

  // Detect when app comes back to foreground — refresh if date changed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_loadedForDate != _todayKey) {
        // New day — reload quote
        _quotes.clear();
        _currentIndex = 0;
        _loadQuotes();
      }
    }
  }

  Future<void> _loadQuotes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    _loadedForDate = _todayKey;

    // Load today's daily quote (cache keyed to date — auto-fresh each day)
    final first = await QuoteService.getDailyQuote();
    if (first != null && mounted) {
      setState(() {
        _quotes.add(first);
        _isLoading = false;
      });
      _slideController.forward();
      _startAutoSlide();
    } else if (mounted) {
      setState(() => _isLoading = false);
    }

    // Fetch additional quotes in background for rotation
    for (int i = 1; i < _fetchCount; i++) {
      final q = await QuoteService.fetchRandomQuote();
      if (q != null && mounted) {
        setState(() => _quotes.add(q));
      }
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_quotes.length > 1) _nextQuote();
    });
  }

  void _nextQuote() {
    if (_quotes.isEmpty) return;
    _slideController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % _quotes.length;
      });
      _slideController.forward();
    });
  }

  void _prevQuote() {
    if (_quotes.isEmpty) return;
    _slideController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentIndex =
            (_currentIndex - 1 + _quotes.length) % _quotes.length;
      });
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSlideTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1E3A5F), const Color(0xFF2D5A87)]
                : [const Color(0xFF0A3D8F), const Color(0xFF1E88E5)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    if (_quotes.isEmpty) return const SizedBox.shrink();

    final quote = _quotes[_currentIndex];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E3A5F),
                  const Color(0xFF2D5A87),
                  const Color(0xFF3D7AB5),
                ]
              : [
                  const Color(0xFF0A3D8F),
                  const Color(0xFF1565C0),
                  const Color(0xFF1E88E5),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF1E3A5F).withValues(alpha: 0.4)
                : AppColors.shadowPrimary,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -200) {
              _nextQuote();
              _startAutoSlide();
            } else if (details.primaryVelocity! > 200) {
              _prevQuote();
              _startAutoSlide();
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: AnimatedBuilder(
                    animation: _slideController,
                    builder: (_, child) => FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideIn,
                        child: child,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '"${quote.text}"',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '— ${quote.author}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                if (_quotes.length > 1) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_quotes.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        width: 5,
                        height: i == _currentIndex ? 12 : 5,
                        decoration: BoxDecoration(
                          color: i == _currentIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                ],

                GestureDetector(
                  onTap: () {
                    _nextQuote();
                    _startAutoSlide();
                  },
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 4),

                GestureDetector(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
