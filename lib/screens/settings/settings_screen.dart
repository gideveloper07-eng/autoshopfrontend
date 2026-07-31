import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/language_provider.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _primary   = Color(0xFF1A56DB);
  static const Color _secondary = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final l10n             = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context);
    final theme            = Theme.of(context);
    final isDark           = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(context, l10n),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildLanguageCard(context, l10n, languageProvider),
                  const SizedBox(height: 16),
                  _buildThemeCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AppLocalizations l10n) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3A8F), _primary, _secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x551A56DB), blurRadius: 20, offset: Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 16, 18),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: const Icon(Icons.settings_rounded,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.settings,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Language card ──────────────────────────────────────────────────────────

  Widget _buildLanguageCard(
    BuildContext context,
    AppLocalizations l10n,
    LanguageProvider languageProvider,
  ) {
    final theme = Theme.of(context);
    final cardBg = theme.colorScheme.surface;
    final textDark = theme.colorScheme.onSurface;
    final textMid = theme.colorScheme.onSurface.withOpacity(0.6);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1),
        boxShadow: [
          BoxShadow(
              color: _primary.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLanguageDialog(context, l10n, languageProvider),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.language,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: textDark)),
                      const SizedBox(height: 4),
                      Text(languageProvider.currentLanguageName,
                          style: TextStyle(
                              fontSize: 13,
                              color: textMid,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: textMid),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Theme card ─────────────────────────────────────────────────────────────

  Widget _buildThemeCard(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, tp, _) {
        final isAuto      = tp.isAuto;
        final isDark      = tp.isDark;
        final theme       = Theme.of(context);
        final cardBg      = theme.colorScheme.surface;
        final onSurface   = theme.colorScheme.onSurface;
        final textMid     = theme.colorScheme.onSurface.withOpacity(0.6);

        return Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor, width: 1),
            boxShadow: [
              BoxShadow(
                  color: _primary.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header row ───────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [const Color(0xFF3B4A6B), const Color(0xFF1A2535)]
                              : [const Color(0xFFFFC107), const Color(0xFFFF9800)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAuto
                            ? Icons.auto_awesome_rounded
                            : isDark
                                ? Icons.nightlight_round
                                : Icons.wb_sunny_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface)),
                          const SizedBox(height: 3),
                          Text(
                            isAuto
                                ? 'Auto  •  ${tp.autoStatusLabel}'
                                : isDark
                                    ? 'Dark Mode'
                                    : 'Light Mode',
                            style: TextStyle(
                                fontSize: 13,
                                color: textMid,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // ── Section label ────────────────────────────────────
                Text(
                  'THEME MODE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMid.withOpacity(0.65),
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 10),

                // ══════════════════════════════════════════════════════
                // OPTION 1 — MANUAL
                // Active when isAuto = false.  Fades to 35% when auto is ON.
                // ══════════════════════════════════════════════════════
                AnimatedOpacity(
                  opacity: isAuto ? 0.38 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: !isAuto
                          ? _primary.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: !isAuto
                            ? _primary.withOpacity(0.22)
                            : Colors.grey.withOpacity(0.12),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Icon(
                          isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                          size: 20,
                          color: !isAuto ? _primary : textMid,
                        ),
                        const SizedBox(width: 12),

                        // Label
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manual',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: !isAuto ? onSurface : textMid,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isAuto
                                    ? 'Disabled while Auto is ON'
                                    : isDark
                                        ? 'Currently: Dark — tap to switch Light'
                                        : 'Currently: Light — tap to switch Dark',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textMid.withOpacity(0.75),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Toggle — disabled (null onTap) when auto is ON
                        GestureDetector(
                          onTap: isAuto ? null : () => tp.toggleTheme(),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: 52,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: !isAuto && isDark
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey.shade300,
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                  left: isDark ? 26 : 2,
                                  top: 2,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isDark
                                          ? Icons.dark_mode
                                          : Icons.light_mode,
                                      size: 13,
                                      color: isDark
                                          ? const Color(0xFF1565C0)
                                          : const Color(0xFFFFA000),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ══════════════════════════════════════════════════════
                // OPTION 2 — AUTO (sunrise / sunset)
                // Switch turns auto ON/OFF.  When ON, manual is faded.
                // ══════════════════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isAuto
                        ? _primary.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAuto
                          ? _primary.withOpacity(0.22)
                          : Colors.grey.withOpacity(0.12),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Animated icon
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Icon(
                              isAuto
                                  ? (isDark
                                      ? Icons.nights_stay_rounded
                                      : Icons.wb_sunny_rounded)
                                  : Icons.auto_awesome_rounded,
                              key: ValueKey(isAuto
                                  ? (isDark ? 'moon' : 'sun')
                                  : 'off'),
                              size: 20,
                              color: isAuto ? _primary : textMid,
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Auto (Sunrise / Sunset)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isAuto ? onSurface : textMid,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isAuto
                                      ? 'Now: ${tp.autoStatusLabel}'
                                      : 'Light at sunrise · Dark at sunset',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textMid.withOpacity(0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ON/OFF switch
                          Switch(
                            value: isAuto,
                            activeColor: _primary,
                            onChanged: (val) => tp.setScheduleMode(
                              val
                                  ? ThemeScheduleMode.auto
                                  : ThemeScheduleMode.manual,
                            ),
                          ),
                        ],
                      ),

                      // ── Time pickers expand when auto is ON ──────────
                      if (isAuto) ...[
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _TimePickerTile(
                                icon: Icons.wb_sunny_rounded,
                                iconColor: const Color(0xFFFF9800),
                                label: 'Sunrise → Light',
                                time: tp.sunriseTime,
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: tp.sunriseTime,
                                    helpText: 'Set Sunrise Time',
                                  );
                                  if (picked != null) tp.setSunriseTime(picked);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TimePickerTile(
                                icon: Icons.nights_stay_rounded,
                                iconColor: const Color(0xFF3B4A6B),
                                label: 'Sunset → Dark',
                                time: tp.sunsetTime,
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: tp.sunsetTime,
                                    helpText: 'Set Sunset Time',
                                  );
                                  if (picked != null) tp.setSunsetTime(picked);
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 13, color: textMid),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Checks every minute. Tap a time to adjust.',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: textMid.withOpacity(0.65)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Banner: Auto is ON → manual is disabled ──────────
                if (isAuto) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: Colors.amber.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 15, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Auto mode is ON — manual toggle is disabled. '
                            'Turn off Auto to change theme manually.',
                            style: TextStyle(
                                fontSize: 12,
                                color: textMid,
                                height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Language dialog ────────────────────────────────────────────────────────

  void _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    LanguageProvider languageProvider,
  ) {
    final theme = Theme.of(context);
    final textDark = theme.colorScheme.onSurface;
    final textMid = theme.colorScheme.onSurface.withOpacity(0.6);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primary, _secondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.language_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(l10n.selectLanguage,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textDark)),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: LanguageProvider.supportedLanguages.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = LanguageProvider.supportedLanguages.entries
                  .elementAt(index);
              final code       = entry.key;
              final name       = entry.value;
              final isSelected =
                  languageProvider.locale.languageCode == code;

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _primary.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        code.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? _primary : textMid,
                        ),
                      ),
                    ),
                  ),
                  title: Text(name,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? _primary : textDark)),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded,
                          color: _primary, size: 24)
                      : null,
                  onTap: () async {
                    await languageProvider.changeLanguage(code);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(children: [
                            const Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 12),
                            Text(l10n.languageChanged),
                          ]),
                          backgroundColor: _primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Time picker tile ──────────────────────────────────────────────────────────

class _TimePickerTile extends StatelessWidget {
  final IconData     icon;
  final Color        iconColor;
  final String       label;
  final TimeOfDay    time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: iconColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11,
                          color: iconColor,
                          fontWeight: FontWeight.w600)),
                  Text(_fmt(time),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                ],
              ),
            ),
            Icon(Icons.edit_outlined,
                size: 14, color: iconColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ignore_for_file: deprecated_member_use
