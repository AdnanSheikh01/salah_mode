import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════
  //  DARK MODE — Deep Forest Emerald + Islamic Gold
  // ═══════════════════════════════════════════════════════════════

  static const Color darkMainBg = Color(0xFF0E1A14); // deep forest
  static const Color darkCard = Color(0xFF152B1E); // elevated surface
  static const Color darkCardAlt = Color(0xFF1A3D2B); // second elevation
  static const Color darkCardRaised = Color(0xFF1E4830); // third elevation
  static const Color darkAccent = Color(
    0xFFC8A84B,
  ); // Islamic gold — primary CTA
  static const Color darkAccentGreen = Color(
    0xFF2ECC71,
  ); // active / live indicator
  static const Color darkAccentMuted = Color(
    0xFF6BA882,
  ); // secondary interactive
  static const Color darkBorder = Color(0xFF1E4830); // subtle dividers
  static const Color darkBorderAccent = Color(0xFF2D6A45); // highlighted border
  static const Color darkInputFill = Color(0x22C8A84B); // gold tint input bg

  // Text
  static const Color darkTextPrimary = Color(
    0xFFE8D9A0,
  ); // warm cream — main text
  static const Color darkTextSecondary = Color(0xFF8FB89E); // muted green-grey
  static const Color darkTextTertiary = Color(
    0xFF5A7A65,
  ); // placeholder / disabled
  static const Color darkTextGold = Color(0xFFC8A84B); // gold emphasis
  static const Color darkTextOnAccent = Color(
    0xFF0E1A14,
  ); // text on gold button

  // ═══════════════════════════════════════════════════════════════
  //  LIGHT MODE — Warm Parchment + Deep Emerald + Antique Gold
  // ═══════════════════════════════════════════════════════════════

  static const Color lightMainBg = Color(0xFFF5F0E8); // warm parchment
  static const Color lightCard = Color(0xFFFFFFFF); // pure white card
  static const Color lightCardAlt = Color(
    0xFFE8EDE8,
  ); // soft green-tint surface
  static const Color lightCardRaised = Color(
    0xFFD9EDE0,
  ); // deeper tinted surface
  static const Color lightAccent = Color(
    0xFF1A6B45,
  ); // deep emerald — primary CTA
  static const Color lightAccentGold = Color(
    0xFF8B6914,
  ); // antique gold — emphasis
  static const Color lightAccentMuted = Color(
    0xFF4A8B6A,
  ); // secondary interactive
  static const Color lightBorder = Color(0xFFD9CFB8); // warm parchment border
  static const Color lightBorderAccent = Color(0xFF1A6B45); // emerald border
  static const Color lightInputFill = Color(0xFFECF3EE); // faint emerald fill

  // Text
  static const Color lightTextPrimary = Color(0xFF1A2E20); // deep forest ink
  static const Color lightTextSecondary = Color(0xFF4A6B58); // muted forest
  static const Color lightTextTertiary = Color(
    0xFF8BA898,
  ); // placeholder / disabled
  static const Color lightTextGold = Color(0xFF8B6914); // antique gold emphasis
  static const Color lightTextOnAccent = Color(
    0xFFF5F0E8,
  ); // parchment on emerald btn

  // ═══════════════════════════════════════════════════════════════
  //  SEMANTIC / SHARED
  // ═══════════════════════════════════════════════════════════════

  static const Color colorError = Color(0xFFD94F4F);
  static const Color colorSuccess = Color(0xFF2ECC71);
  static const Color colorWarning = Color(0xFFF0A500);
  static const Color colorInfo = Color(0xFF3B8BD4);

  // Prayer-time specific
  static const Color fajrColor = Color(0xFF5B7FA6); // pre-dawn blue
  static const Color shuruqColor = Color(0xFFF0A500); // sunrise amber
  static const Color dhuhrColor = Color(0xFF2ECC71); // midday green
  static const Color asrColor = Color(0xFFE8883A); // afternoon orange
  static const Color maghribColor = Color(0xFFD94F4F); // sunset red
  static const Color ishaColor = Color(0xFF7B68EE); // night purple

  // ═══════════════════════════════════════════════════════════════
  //  TYPOGRAPHY HELPERS
  // ═══════════════════════════════════════════════════════════════

  /// Amiri — best for Arabic / Quranic text. Add to pubspec.yaml:
  ///   google_fonts: ^6.x
  ///   then use: GoogleFonts.amiri()
  ///
  /// App body font: Poppins (as set in fontFamily)
  /// For Arabic verses use textDirection: TextDirection.rtl
  ///   and fontFamily: 'Amiri' or GoogleFonts.amiri().fontFamily

  // ═══════════════════════════════════════════════════════════════
  //  LIGHT THEME
  // ═══════════════════════════════════════════════════════════════

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Poppins',

    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: lightAccent,
      onPrimary: lightTextOnAccent,
      primaryContainer: lightCardRaised,
      onPrimaryContainer: lightTextPrimary,
      secondary: lightAccentGold,
      onSecondary: lightTextOnAccent,
      secondaryContainer: Color(0xFFFAF3DC),
      onSecondaryContainer: Color(0xFF5C4200),
      tertiary: lightAccentMuted,
      onTertiary: lightTextOnAccent,
      tertiaryContainer: lightCardAlt,
      onTertiaryContainer: lightTextSecondary,
      error: colorError,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      background: lightMainBg,
      onBackground: lightTextPrimary,
      surface: lightCard,
      onSurface: lightTextPrimary,
      surfaceVariant: lightCardAlt,
      onSurfaceVariant: lightTextSecondary,
      outline: lightBorder,
      outlineVariant: Color(0xFFE8E0D0),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFF1A3D2B),
      onInverseSurface: darkTextPrimary,
      inversePrimary: darkAccentGreen,
    ),

    scaffoldBackgroundColor: lightMainBg,

    // ── AppBar ─────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: lightMainBg,
      foregroundColor: lightTextPrimary,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: lightAccent, size: 22),
      actionsIconTheme: IconThemeData(color: lightAccent, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),

    // ── Bottom Navigation Bar ───────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightCard,
      selectedItemColor: lightAccent,
      unselectedItemColor: lightTextTertiary,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // ── Navigation Bar (Material 3) ─────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightCard,
      indicatorColor: lightCardRaised,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: lightAccent, size: 22);
        }
        return const IconThemeData(color: lightTextTertiary, size: 22);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: lightAccent,
          );
        }
        return const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: lightTextTertiary,
        );
      }),
      elevation: 8,
    ),

    // ── Cards ───────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightCard,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: lightBorder, width: 0.8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),

    // ── Elevated Button ─────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: lightAccent,
        foregroundColor: lightTextOnAccent,
        disabledBackgroundColor: lightCardAlt,
        disabledForegroundColor: lightTextTertiary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Outlined Button ─────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightAccent,
        side: const BorderSide(color: lightAccent, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Text Button ─────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: lightAccent,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Floating Action Button ──────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: lightAccent,
      foregroundColor: lightTextOnAccent,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── Input Decoration ────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: lightTextTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: lightTextSecondary,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: lightAccent,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: lightTextSecondary,
      suffixIconColor: lightTextSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: lightAccent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: colorError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: colorError, width: 1.8),
      ),
    ),

    // ── Text Theme ──────────────────────────────────────────────
    textTheme: const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.1,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: lightTextPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: lightTextTertiary,
        height: 1.4,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: lightTextSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: lightTextTertiary,
        letterSpacing: 0.5,
      ),
    ),

    // ── Chip ────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: lightCardAlt,
      selectedColor: lightCardRaised,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: lightTextSecondary,
      ),
      side: const BorderSide(color: lightBorder, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Divider ─────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 0.8,
      space: 1,
    ),

    // ── ListTile ────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: lightTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
      ),
      iconColor: lightAccent,
    ),

    // ── Switch ──────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return lightTextOnAccent;
        return lightTextTertiary;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return lightAccent;
        return lightCardAlt;
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.transparent;
        return lightBorder;
      }),
    ),

    // ── Slider ──────────────────────────────────────────────────
    sliderTheme: const SliderThemeData(
      activeTrackColor: lightAccent,
      inactiveTrackColor: lightCardRaised,
      thumbColor: lightAccent,
      overlayColor: Color(0x221A6B45),
      valueIndicatorColor: lightAccent,
      valueIndicatorTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: lightTextOnAccent,
        fontSize: 13,
      ),
    ),

    // ── Progress Indicator ──────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: lightAccent,
      linearTrackColor: lightCardRaised,
      circularTrackColor: lightCardAlt,
    ),

    // ── Tab Bar ─────────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      labelColor: lightAccent,
      unselectedLabelColor: lightTextTertiary,
      indicatorColor: lightAccent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── Dialog ──────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: lightBorder, width: 0.8),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: lightTextPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightTextSecondary,
        height: 1.5,
      ),
    ),

    // ── Bottom Sheet ────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: lightCard,
      modalBackgroundColor: lightCard,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: lightBorder,
      dragHandleSize: Size(40, 4),
    ),

    // ── SnackBar ────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightTextPrimary,
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: lightMainBg,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: lightAccentGold,
    ),

    // ── Tooltip ─────────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: lightTextPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: lightMainBg,
        fontSize: 12,
      ),
    ),

    // ── Icon ────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: lightTextSecondary, size: 22),
    primaryIconTheme: const IconThemeData(color: lightAccent, size: 22),
  );

  // ═══════════════════════════════════════════════════════════════
  //  DARK THEME
  // ═══════════════════════════════════════════════════════════════

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Poppins',

    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: darkAccent,
      onPrimary: darkTextOnAccent,
      primaryContainer: darkCardAlt,
      onPrimaryContainer: darkTextPrimary,
      secondary: darkAccentGreen,
      onSecondary: darkTextOnAccent,
      secondaryContainer: Color(0xFF0E3020),
      onSecondaryContainer: Color(0xFFB7F5D4),
      tertiary: darkAccentMuted,
      onTertiary: darkTextOnAccent,
      tertiaryContainer: darkCard,
      onTertiaryContainer: darkTextSecondary,
      error: colorError,
      onError: Colors.white,
      errorContainer: Color(0xFF8C1D18),
      onErrorContainer: Color(0xFFF9DEDC),
      background: darkMainBg,
      onBackground: darkTextPrimary,
      surface: darkCard,
      onSurface: darkTextPrimary,
      surfaceVariant: darkCardAlt,
      onSurfaceVariant: darkTextSecondary,
      outline: darkBorder,
      outlineVariant: Color(0xFF1A3520),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: lightCard,
      onInverseSurface: lightTextPrimary,
      inversePrimary: lightAccent,
    ),

    scaffoldBackgroundColor: darkMainBg,

    // ── AppBar ─────────────────────────────────────────────────
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      backgroundColor: darkMainBg,
      foregroundColor: darkTextPrimary,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: 0.2,
      ),
      iconTheme: IconThemeData(color: darkAccent, size: 22),
      actionsIconTheme: IconThemeData(color: darkAccent, size: 22),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    ),

    // ── Bottom Navigation Bar ───────────────────────────────────
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkCard,
      selectedItemColor: darkAccent,
      unselectedItemColor: darkTextTertiary,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w400,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    // ── Navigation Bar (Material 3) ─────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkCard,
      indicatorColor: darkCardAlt,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: darkAccent, size: 22);
        }
        return const IconThemeData(color: darkTextTertiary, size: 22);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: darkAccent,
          );
        }
        return const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w400,
          color: darkTextTertiary,
        );
      }),
      elevation: 8,
    ),

    // ── Cards ───────────────────────────────────────────────────
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 0.8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),

    // ── Elevated Button ─────────────────────────────────────────
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkAccent,
        foregroundColor: darkTextOnAccent,
        disabledBackgroundColor: darkCardAlt,
        disabledForegroundColor: darkTextTertiary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Outlined Button ─────────────────────────────────────────
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkAccent,
        side: const BorderSide(color: darkAccent, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    ),

    // ── Text Button ─────────────────────────────────────────────
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkAccent,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // ── Floating Action Button ──────────────────────────────────
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: darkAccent,
      foregroundColor: darkTextOnAccent,
      elevation: 4,
      shape: CircleBorder(),
    ),

    // ── Input Decoration ────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkInputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: darkTextTertiary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: darkTextSecondary,
        fontSize: 14,
      ),
      floatingLabelStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: darkAccent,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: darkTextSecondary,
      suffixIconColor: darkTextSecondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkBorder, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: darkAccent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: colorError, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: colorError, width: 1.8),
      ),
    ),

    // ── Text Theme ──────────────────────────────────────────────
    textTheme: const TextTheme(
      // Display
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        letterSpacing: -1.5,
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        letterSpacing: -0.5,
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      // Headline
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
      ),
      // Title
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: 0.1,
      ),
      // Body
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkTextPrimary,
        height: 1.6,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: darkTextTertiary,
        height: 1.4,
      ),
      // Label
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: darkTextPrimary,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: darkTextTertiary,
        letterSpacing: 0.5,
      ),
    ),

    // ── Chip ────────────────────────────────────────────────────
    chipTheme: ChipThemeData(
      backgroundColor: darkCardAlt,
      selectedColor: darkCardRaised,
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: darkTextSecondary,
      ),
      side: const BorderSide(color: darkBorder, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    ),

    // ── Divider ─────────────────────────────────────────────────
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 0.8,
      space: 1,
    ),

    // ── ListTile ────────────────────────────────────────────────
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: darkTextPrimary,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
      ),
      iconColor: darkAccent,
    ),

    // ── Switch ──────────────────────────────────────────────────
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return darkTextOnAccent;
        return darkTextTertiary;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return darkAccent;
        return darkCardAlt;
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) return Colors.transparent;
        return darkBorder;
      }),
    ),

    // ── Slider ──────────────────────────────────────────────────
    sliderTheme: const SliderThemeData(
      activeTrackColor: darkAccent,
      inactiveTrackColor: darkCardRaised,
      thumbColor: darkAccent,
      overlayColor: Color(0x22C8A84B),
      valueIndicatorColor: darkAccent,
      valueIndicatorTextStyle: TextStyle(
        fontFamily: 'Poppins',
        color: darkTextOnAccent,
        fontSize: 13,
      ),
    ),

    // ── Progress Indicator ──────────────────────────────────────
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: darkAccent,
      linearTrackColor: darkCardRaised,
      circularTrackColor: darkCardAlt,
    ),

    // ── Tab Bar ─────────────────────────────────────────────────
    tabBarTheme: const TabBarThemeData(
      labelColor: darkAccent,
      unselectedLabelColor: darkTextTertiary,
      indicatorColor: darkAccent,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),

    // ── Dialog ──────────────────────────────────────────────────
    dialogTheme: DialogThemeData(
      backgroundColor: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: darkBorder, width: 0.8),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: darkTextPrimary,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: darkTextSecondary,
        height: 1.5,
      ),
    ),

    // ── Bottom Sheet ────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkCard,
      modalBackgroundColor: darkCard,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      dragHandleColor: darkBorder,
      dragHandleSize: Size(40, 4),
    ),

    // ── SnackBar ────────────────────────────────────────────────
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardRaised,
      contentTextStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: darkTextPrimary,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
      actionTextColor: darkAccent,
    ),

    // ── Tooltip ─────────────────────────────────────────────────
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkCardRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: darkBorder),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: darkTextPrimary,
        fontSize: 12,
      ),
    ),

    // ── Icon ────────────────────────────────────────────────────
    iconTheme: const IconThemeData(color: darkTextSecondary, size: 22),
    primaryIconTheme: const IconThemeData(color: darkAccent, size: 22),
  );

  // ═══════════════════════════════════════════════════════════════
  //  EXTENSION HELPERS  —  use via context.islamicTheme
  // ═══════════════════════════════════════════════════════════════

  /// Returns gold color depending on current brightness.
  static Color goldColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : lightAccentGold;
  }

  /// Returns the correct accent-muted (green) depending on brightness.
  static Color accentMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccentMuted
        : lightAccentMuted;
  }

  /// Card decoration with optional gold left border (e.g. highlighted ayah).
  static BoxDecoration cardDecoration(
    BuildContext context, {
    bool goldBorder = false,
    bool elevated = false,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: elevated
          ? (dark ? darkCardAlt : lightCardAlt)
          : (dark ? darkCard : lightCard),
      borderRadius: BorderRadius.circular(16),
      border: Border(
        left: goldBorder
            ? BorderSide(color: dark ? darkAccent : lightAccentGold, width: 3)
            : BorderSide(color: dark ? darkBorder : lightBorder, width: 0.8),
        top: BorderSide(
          color: dark ? darkBorder : lightBorder,
          width: goldBorder ? 0 : 0.8,
        ),
        right: BorderSide(
          color: dark ? darkBorder : lightBorder,
          width: goldBorder ? 0 : 0.8,
        ),
        bottom: BorderSide(
          color: dark ? darkBorder : lightBorder,
          width: goldBorder ? 0 : 0.8,
        ),
      ),
    );
  }

  /// Prayer time color for each prayer name.
  static Color prayerColor(String prayer) {
    switch (prayer.toLowerCase()) {
      case 'fajr':
        return fajrColor;
      case 'shuruq':
        return shuruqColor;
      case 'dhuhr':
        return dhuhrColor;
      case "asr":
        return asrColor;
      case 'maghrib':
        return maghribColor;
      case 'isha':
        return ishaColor;
      default:
        return dhuhrColor;
    }
  }

  /// Text style for Arabic / Quranic verses.
  /// Requires the Amiri font in pubspec.yaml:
  ///   - family: Amiri
  ///     fonts:
  ///       - asset: assets/fonts/Amiri-Regular.ttf
  ///       - asset: assets/fonts/Amiri-Bold.ttf
  ///         weight: 700
  static TextStyle arabicStyle(
    BuildContext context, {
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontFamily: 'Amiri',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? (dark ? darkTextGold : lightAccent),
      height: 2.0,
      letterSpacing: 0,
    );
  }
}
