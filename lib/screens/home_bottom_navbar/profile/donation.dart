import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────
// DONATION TIERS
// ─────────────────────────────────────────────────────────────────

class _Tier {
  final int amount;
  final String label;
  final String impact;
  final String emoji;
  final Color color;

  const _Tier({
    required this.amount,
    required this.label,
    required this.impact,
    required this.emoji,
    required this.color,
  });
}

const List<_Tier> _tiers = [
  _Tier(
    amount: 100,
    label: "Supporter",
    impact: "Covers server costs for 1 day",
    emoji: "🌱",
    color: AppTheme.colorSuccess,
  ),
  _Tier(
    amount: 250,
    label: "Contributor",
    impact: "Funds one feature improvement",
    emoji: "⭐",
    color: AppTheme.colorInfo,
  ),
  _Tier(
    amount: 500,
    label: "Guardian",
    impact: "Supports 1 week of development",
    emoji: "🛡️",
    color: AppTheme.colorWarning,
  ),
  _Tier(
    amount: 1000,
    label: "Benefactor",
    impact: "Keeps the app free for the Ummah",
    emoji: "🕌",
    color: AppTheme.ishaColor,
  ),
];

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  int? _selectedAmount;
  bool _donating = false;
  String _currency = '₹'; // ₹ | $ | £ | د.إ
  final _customCtrl = TextEditingController();
  String? _customError;

  static const Map<String, String> _currencies = {
    '₹': 'INR — Indian Rupee',
    '\$': 'USD — US Dollar',
    '£': 'GBP — British Pound',
    'د.إ': 'AED — UAE Dirham',
  };

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  // ── Donation action ───────────────────────────────────────────
  Future<void> _donate(int amount) async {
    if (_donating || amount <= 0) return;
    setState(() {
      _donating = true;
      _selectedAmount = amount;
    });

    try {
      // ── Open payment URL (replace with Stripe / Razorpay / PayPal) ─
      const payUrl = 'https://donate.salahmode.app'; // your real URL
      final uri = Uri.parse('$payUrl?amount=$amount&currency=$_currency');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback — show confirmation snack if URL can't open
        _showSnack(
          "جَزَاكَ اللّٰهُ خَيْرًا",
          "Thank you! $_currency$amount — may Allah reward you.",
          isSuccess: true,
        );
      }
    } catch (e) {
      debugPrint("Donation error: $e");
      _showSnack(
        "Something went wrong",
        "Please try again or contact support.",
        isSuccess: false,
      );
    } finally {
      if (mounted) setState(() => _donating = false);
    }
  }

  void _submitCustom() {
    final raw = _customCtrl.text.trim();
    final amount = int.tryParse(raw);
    if (raw.isEmpty) {
      setState(() => _customError = "Please enter an amount.");
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _customError = "Please enter a valid amount.");
      return;
    }
    if (amount < 10) {
      setState(() => _customError = "Minimum donation is $_currency 10.");
      return;
    }
    setState(() => _customError = null);
    _donate(amount);
  }

  void _showSnack(String title, String msg, {required bool isSuccess}) {
    if (Get.isSnackbarOpen) Get.closeCurrentSnackbar();
    Get.snackbar(
      title,
      msg,
      backgroundColor: isSuccess ? AppTheme.colorSuccess : AppTheme.colorError,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  // ─────────────────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkMainBg : AppTheme.lightMainBg;
    final cardColor = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final cardAltColor = isDark ? AppTheme.darkCardAlt : AppTheme.lightCardAlt;
    final accentColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccent;
    final goldColor = isDark ? AppTheme.darkAccent : AppTheme.lightAccentGold;
    final textPrimary = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightTextPrimary;
    final textSecondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;
    final textTertiary = isDark
        ? AppTheme.darkTextTertiary
        : AppTheme.lightTextTertiary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final inputFill = isDark ? AppTheme.darkInputFill : AppTheme.lightInputFill;
    final btnTextColor = isDark
        ? AppTheme.darkTextOnAccent
        : AppTheme.lightTextOnAccent;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: accentColor, size: 20),
        title: Text(
          "Support Salah Mode",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        actions: [
          // Currency picker
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showCurrencySheet(
                cardColor: cardColor,
                borderColor: borderColor,
                accentColor: accentColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                btnTextColor: btnTextColor,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _currency,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 15,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: btnTextColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 32,
                      color: btnTextColor,
                    ),
                  ),

                  const SizedBox(height: 6),
                  Text(
                    "Support Salah Mode",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: btnTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Help us keep the app free and improve Islamic features for the entire Ummah.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: btnTextColor.withOpacity(0.75),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Donation tiers ────────────────────────────────────
            _SectionLabel(
              label: "Choose an Amount",
              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: _tiers.map((t) {
                final sel = _selectedAmount == t.amount;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAmount = t.amount);
                    _donate(t.amount);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: sel ? t.color.withOpacity(0.10) : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? t.color.withOpacity(0.50) : borderColor,
                        width: sel ? 1.5 : 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(t.emoji, style: const TextStyle(fontSize: 16)),
                            const Spacer(),
                            if (sel)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: t.color,
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          "$_currency${t.amount}",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: sel ? t.color : textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: sel ? t.color : textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Custom amount ─────────────────────────────────────
            _SectionLabel(
              label: "Custom Amount",
              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _customCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    onChanged: (_) => setState(() => _customError = null),
                    decoration: InputDecoration(
                      hintText: "Enter amount",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: textTertiary,
                      ),
                      errorText: _customError,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          _currency,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minHeight: 50,
                      ),
                      filled: true,
                      fillColor: inputFill,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accentColor, width: 1.4),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppTheme.colorError,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _donating ? null : _submitCustom,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _donating
                            ? accentColor.withOpacity(0.50)
                            : accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _donating
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: btnTextColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite_rounded,
                                  size: 17,
                                  color: btnTextColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Donate Now",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: btnTextColor,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Impact breakdown ──────────────────────────────────
            _SectionLabel(
              label: "Where It Goes",

              goldColor: goldColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                children: [
                  _ImpactRow(
                    pct: 0.50,
                    label: "Server & Hosting",
                    color: accentColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 10),
                  _ImpactRow(
                    pct: 0.30,
                    label: "New Feature Development",
                    color: AppTheme.colorSuccess,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 10),
                  _ImpactRow(
                    pct: 0.15,
                    label: "Design & Accessibility",
                    color: AppTheme.colorWarning,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                  const SizedBox(height: 10),
                  _ImpactRow(
                    pct: 0.05,
                    label: "Islamic Content Curation",
                    color: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    borderColor: borderColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Tier impact list ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardAltColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: goldColor.withOpacity(0.20),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: goldColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Your Impact",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._tiers.map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: t.color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: t.color.withOpacity(0.25),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              "$_currency${t.amount}",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: t.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t.impact,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: textSecondary,
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

            const SizedBox(height: 24),

            // ── Closing dua ───────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: goldColor.withOpacity(0.25),
                  width: 0.8,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 28,
                        height: 0.7,
                        color: goldColor.withOpacity(0.35),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "✦",
                        style: TextStyle(fontSize: 12, color: goldColor),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 28,
                        height: 0.7,
                        color: goldColor.withOpacity(0.35),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "مَنْ دَلَّ عَلَى خَيْرٍ فَلَهُ مِثْلُ أَجْرِ فَاعِلِهِ",
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: goldColor,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Whoever guides to good receives the same reward as the one who does it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "— Sahih Muslim 1893",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      color: textTertiary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "May Allah reward you for supporting this effort 🤲",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: accentColor,
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

  // ── Currency bottom sheet ─────────────────────────────────────
  void _showCurrencySheet({
    required Color cardColor,
    required Color borderColor,
    required Color accentColor,
    required Color textPrimary,
    required Color textSecondary,
    required Color btnTextColor,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(
        0x00000000,
      ), // transparent — sheet draws its own bg
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: borderColor, width: 0.8)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Select Currency",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            ..._currencies.entries.map((e) {
              final sel = _currency == e.key;
              return GestureDetector(
                onTap: () {
                  setState(() => _currency = e.key);
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? accentColor.withOpacity(0.08)
                        : accentColor.withOpacity(0.0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sel ? accentColor.withOpacity(0.40) : borderColor,
                      width: sel ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        e.key,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: sel ? accentColor : textPrimary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          e.value,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: sel ? accentColor : textSecondary,
                          ),
                        ),
                      ),
                      if (sel)
                        Icon(Icons.check_rounded, size: 18, color: accentColor),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  IMPACT ROW (progress bar)
// ═══════════════════════════════════════════════════════════════════

class _ImpactRow extends StatelessWidget {
  final double pct;
  final String label;
  final Color color, textPrimary, textSecondary, borderColor;

  const _ImpactRow({
    required this.pct,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        flex: 3,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: textSecondary,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 4,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 7,
            backgroundColor: borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        "${(pct * 100).round()}%",
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════
//  SECTION LABEL
// ═══════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color goldColor, textPrimary;
  const _SectionLabel({
    required this.label,
    required this.goldColor,
    required this.textPrimary,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 3,
        height: 16,
        decoration: BoxDecoration(
          color: goldColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
    ],
  );
}
