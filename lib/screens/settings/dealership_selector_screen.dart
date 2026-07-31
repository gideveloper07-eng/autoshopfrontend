import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../home/home_screen.dart';

class DealershipSelectorScreen extends StatefulWidget {
  /// Set [fromHome] to true when opened from the home screen switch button.
  /// The selector will pop back to home instead of replacing the stack.
  final bool fromHome;
  const DealershipSelectorScreen({super.key, this.fromHome = false});

  @override
  State<DealershipSelectorScreen> createState() =>
      _DealershipSelectorScreenState();
}

class _DealershipSelectorScreenState extends State<DealershipSelectorScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> dealerships = [];
  bool isLoading = true;
  int? selectedIndex;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  // ── Brand colours (match login screen) ──────────────────────────────────────
  static const Color kBlueDark = Color(0xFF0D47A1);
  static const Color kSteel = Color(0xFFB9C7D9);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    loadData();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final data = await ApiService.getAccessibleDatabases();
      setState(() {
        dealerships = List<dynamic>.from(data);
        isLoading = false;
      });
      _animCtrl.forward();
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> selectDealership(
    Map<String, dynamic> dealership,
    int index,
  ) async {
    setState(() => selectedIndex = index);
    try {
      final result = await ApiService.switchDatabase(
        dealership['unqid'].toString(),
      );
      if (result != null && result['success'] == true) {
        // Save new token + database info so every future API call uses the
        // selected company's database
        await ApiService.updateCurrentDatabase(
          token: result['token'],
          databaseName: result['databaseName'] ?? '',
          companyCode: result['propertyCode'] ?? '',
          clientId: dealership['unqid'].toString(),
        );

        if (!mounted) return;

        if (widget.fromHome) {
          // Called from home screen — just go back, home will refresh itself
          Navigator.pop(context);
        } else {
          // Called after login — replace entire stack with HomeScreen
          final session = await ApiService.getUserSession();
          final userName = session?['userName'] ?? '';
          final userEmail = session?['userEmail'] ?? '';

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'HomeScreen'),
              builder: (_) =>
                  HomeScreen(userName: userName, userEmail: userEmail),
            ),
            (route) => false,
          );
        }
      } else {
        setState(() => selectedIndex = null);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?['message'] ?? 'Failed to switch dealership'),
            backgroundColor: kBlueDark,
          ),
        );
      }
    } catch (e) {
      setState(() => selectedIndex = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: kBlueDark),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0A1F3D), const Color(0xFF1A3A6E), const Color(0xFF2A4A8E)]
                : [const Color(0xFF0D3F8A), const Color(0xFF2C6CE0), const Color(0xFF83C4FF)],
            stops: const [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background glows
            Positioned(
              top: -90,
              left: -60,
              child: _bgGlow(220, Colors.white.withOpacity(0.06)),
            ),
            Positioned(
              top: 90,
              right: -90,
              child: _bgGlow(260, Colors.white.withOpacity(0.05)),
            ),
            Positioned(
              bottom: -80,
              left: -90,
              child: _bgGlow(180, Colors.white.withOpacity(0.04)),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bgGlow(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );

  // ── Top hero header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2979FF), Color(0xFF4EA9FF), Color(0xFF83D4FF)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.26), width: 1.3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.16),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.3,
                ),
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MY AUTOSHOP",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Select your dealership to continue",
                    style: TextStyle(
                      fontSize: 12,
                      color: kSteel,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main body ────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              "Loading dealerships...",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (dealerships.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.store_mall_directory_outlined,
                size: 52,
                color: Color(0xFF1565C0),
              ),
              SizedBox(height: 16),
              Text(
                "No Dealerships Available",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10253F),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your account has no accessible dealerships.\nPlease contact your administrator.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF4D6178)),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        itemCount: dealerships.length,
        itemBuilder: (context, index) {
          return _buildDealershipCard(dealerships[index], index);
        },
      ),
    );
  }

  // ── Individual dealership card ───────────────────────────────────────────────
  Widget _buildDealershipCard(dynamic d, int index) {
    final bool isSelected = selectedIndex == index;
    final String name = (d['propertyname'] ?? '').toString().toUpperCase();
    final String code = (d['propertycode'] ?? '').toString().toUpperCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Stagger animation offset per card
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + index * 100),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: isSelected ? null : () => selectDealership(d, index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF1A6BE3), Color(0xFF28A8F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1A2535), const Color(0xFF253545)]
                        : [Colors.white, const Color(0xFFF4FBFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withOpacity(0.4)
                  : isDark
                      ? const Color(0xFF2A3A4A)
                      : const Color(0xFFE6F4FF),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? const Color(0xFF1A6BE3).withOpacity(0.35)
                    : Colors.black.withOpacity(0.09),
                blurRadius: isSelected ? 20 : 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isSelected
                        ? Colors.white.withOpacity(0.22)
                        : const Color(0xFF1565C0).withOpacity(0.08),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white.withOpacity(0.4)
                          : const Color(0xFF1565C0).withOpacity(0.15),
                      width: 1.2,
                    ),
                  ),
                  child: isSelected
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.store_mall_directory_rounded,
                          size: 26,
                          color: const Color(0xFF1565C0),
                        ),
                ),
                const SizedBox(width: 16),
                // Name & code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: isSelected
                              ? Colors.white.withOpacity(0.2)
                              : const Color(0xFF1565C0).withOpacity(0.08),
                        ),
                        child: Text(
                          code,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white.withOpacity(0.9)
                                : const Color(0xFF1565C0),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF1565C0).withOpacity(0.08),
                  ),
                  child: Icon(
                    isSelected
                        ? Icons.hourglass_top_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: isSelected ? Colors.white : const Color(0xFF1565C0),
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
