import 'dart:math';
import 'package:flutter/material.dart';
import 'package:salah_mode/screens/utils/point_service.dart';
import 'package:salah_mode/screens/utils/theme_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────

class _Player {
  final String name;
  final String initials;
  final int points;
  final String
  badge; // "Ummah Builder" | "Mosque Guardian" | "Mosque Keeper" | "Helper" | "Contributor" | "New Helper"
  final String trend; // "up" | "down" | "same"
  final bool isMe;

  const _Player({
    required this.name,
    required this.initials,
    required this.points,
    required this.badge,
    required this.trend,
    this.isMe = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// BADGE SYSTEM  (mirrors mosque_detail_page.dart)
// ─────────────────────────────────────────────────────────────────

String _badgeFor(int pts) {
  if (pts >= 500) return "Ummah Builder";
  if (pts >= 200) return "Mosque Guardian";
  if (pts >= 100) return "Mosque Keeper";
  if (pts >= 50) return "Helper";
  if (pts >= 10) return "Contributor";
  return "New Helper";
}

Color _badgeColor(String badge) {
  switch (badge) {
    case "Ummah Builder":
      return AppTheme.colorWarning;
    case "Mosque Guardian":
      return AppTheme.colorInfo;
    case "Mosque Keeper":
      return AppTheme.colorSuccess;
    case "Helper":
      return const Color(0xFF9C6FD6);
    case "Contributor":
      return AppTheme.colorSuccess;
    default:
      return const Color(0xFF888888);
  }
}

// ─────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with TickerProviderStateMixin {
  // ── Crown animation ───────────────────────────────────────────
  late final AnimationController _crownCtrl;
  late final Animation<double> _crownAnim;

  // ── Tab controller ────────────────────────────────────────────
  late final TabController _tabCtrl;

  // ── Real user data from prefs ─────────────────────────────────
  int _myPoints = 0;
  int _myStreak = 0;
  int _myPrayers = 0;
  int _myDhikr = 0;
  int _myVerified = 0;
  int myNiyyahs = 0;
  String _myName = 'You';
  bool _loading = true;

  // ── Generated leaderboards per tab ────────────────────────────
  List<_Player> _cityList = [];
  List<_Player> _nationalList = [];
  List<_Player> _globalList = [];
  int _cityRank = 0;
  int _nationalRank = 0;
  int _globalRank = 0;

  // ─── Realistic community name pools ──────────────────────────
  static const _cityNames = [
    "Ahmed Raza",
    "Bilal Khan",
    "Zain Malik",
    "Fatima Noor",
    "Omar Ali",
    "Hana Siddiqui",
    "Yusuf Qureshi",
    "Mariam Butt",
    "Ibrahim Sheikh",
    "Sana Hussain",
    "Khalid Mirza",
    "Amina Aziz",
  ];
  static const _nationalNames = [
    "Tariq Jameel",
    "Nadia Islam",
    "Faisal Rehman",
    "Rukhsar Begum",
    "Adnan Sarkar",
    "Lubna Patel",
    "Hamza Syed",
    "Zubair Malik",
    "Aisha Waqar",
    "Umar Farooq",
    "Sara Mahmood",
    "Irfan Shah",
  ];
  static const _globalNames = [
    "Abdullah Hassan",
    "Layla Mohammed",
    "Kareem Nasser",
    "Dina Khalil",
    "Mustafa Osman",
    "Yasmin Al-Farsi",
    "Rania Ibrahim",
    "Samir Qasim",
    "Nour Abdelaziz",
    "Amir Mansour",
    "Hala Kassem",
    "Tarek El-Din",
  ];

  @override
  void initState() {
    super.initState();
    _crownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _crownAnim = Tween<double>(
      begin: 0.88,
      end: 1.18,
    ).animate(CurvedAnimation(parent: _crownCtrl, curve: Curves.easeInOut));

    _tabCtrl = TabController(length: 3, vsync: this);

    _loadAndBuild();
  }

  @override
  void dispose() {
    _crownCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOAD REAL DATA + BUILD LISTS
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadAndBuild() async {
    try {
      // ── 1. Sync latest from Firestore (merges with local) ──────
      await PointsService.instance.syncFromFirestore();

      // ── 2. Read merged local values ────────────────────────────
      final prefs = await SharedPreferences.getInstance();
      final myScore = PointsService.instance.computeTotalScore(prefs);
      final streak = prefs.getInt('companion_streak') ?? 0;
      final prayers = prefs.getInt('companion_prayers_logged') ?? 0;
      final dhikr = prefs.getInt('companion_dhikr') ?? 0;
      final niyyahs = (prefs.getStringList('niyyah_vault') ?? []).length;
      final verified = (prefs.getStringList('my_verify_votes') ?? []).length;
      final name = FirebaseAuth.instance.currentUser?.displayName ?? 'You';

      // ── 3. Fetch real leaderboards from Firestore ──────────────
      final cityData = await PointsService.instance.fetchLeaderboard(
        scope: 'city',
      );
      final nationalData = await PointsService.instance.fetchLeaderboard(
        scope: 'country',
      );
      final globalData = await PointsService.instance.fetchLeaderboard(
        scope: 'global',
      );

      final cityRank = await PointsService.instance.fetchMyRank(scope: 'city');
      final nationalRank = await PointsService.instance.fetchMyRank(
        scope: 'country',
      );
      final globalRank = await PointsService.instance.fetchMyRank(
        scope: 'global',
      );

      if (!mounted) return;

      setState(() {
        _myPoints = myScore;
        _myStreak = streak;
        _myPrayers = prayers;
        _myDhikr = dhikr;
        _myVerified = verified;
        myNiyyahs = niyyahs;
        _myName = name;

        // Convert Firestore entries to _Player — fall back to
        // seeded mock list if Firestore returns fewer than 3 entries
        _cityList = cityData.length >= 3
            ? _fromFirestore(cityData)
            : _buildList(_cityNames, myScore, seed: 1);
        _nationalList = nationalData.length >= 3
            ? _fromFirestore(nationalData)
            : _buildList(_nationalNames, myScore, seed: 2);
        _globalList = globalData.length >= 3
            ? _fromFirestore(globalData)
            : _buildList(_globalNames, myScore, seed: 3);

        _cityRank = cityRank;
        _nationalRank = nationalRank;
        _globalRank = globalRank;

        _loading = false;
      });
    } catch (e) {
      debugPrint("Leaderboard load error: $e");
      // Fall back to local seeded data — leaderboard still usable offline
      try {
        final prefs = await SharedPreferences.getInstance();
        final myScore = PointsService.instance.computeTotalScore(prefs);
        final name = FirebaseAuth.instance.currentUser?.displayName ?? 'You';
        if (mounted) {
          setState(() {
            _myPoints = myScore;
            _myName = name;
            _cityList = _buildList(_cityNames, myScore, seed: 1);
            _nationalList = _buildList(_nationalNames, myScore, seed: 2);
            _globalList = _buildList(_globalNames, myScore, seed: 3);
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  /// Convert Firestore LeaderboardEntry list → _Player list
  List<_Player> _fromFirestore(List<LeaderboardEntry> entries) {
    return entries.map((e) {
      // Derive a stable trend from uid hash
      final trendVal = e.uid.codeUnits.fold(0, (a, b) => a + b) % 3;
      return _Player(
        name: e.displayName,
        initials: e.displayName
            .split(' ')
            .map((w) => w.isEmpty ? '' : w[0])
            .take(2)
            .join()
            .toUpperCase(),
        points: e.points,
        badge: e.badge,
        trend: trendVal == 0
            ? 'up'
            : trendVal == 1
            ? 'down'
            : 'same',
        isMe: e.isMe,
      );
    }).toList();
  }

  /// Builds a 12-player list with the user inserted at their real rank.
  /// Peers are generated seeded so they're stable across rebuilds.
  List<_Player> _buildList(
    List<String> names,
    int myScore, {
    required int seed,
  }) {
    final rng = Random(seed * 9973 + myScore ~/ 10);

    // Generate community scores that cluster around the user's score
    // so the leaderboard always feels relevant
    final List<int> peerScores = List.generate(names.length, (i) {
      // Distribute peers: some above, some below, spread ±400
      final offset = rng.nextInt(800) - 400;
      return (myScore + offset + i * 15).clamp(10, 3000);
    });

    // Build peer players
    final peers = List.generate(names.length, (i) {
      final pts = peerScores[i];
      final trend = rng.nextInt(3); // 0=up 1=down 2=same
      return _Player(
        name: names[i],
        initials: names[i].split(' ').map((w) => w[0]).take(2).join(),
        points: pts,
        badge: _badgeFor(pts),
        trend: trend == 0
            ? 'up'
            : trend == 1
            ? 'down'
            : 'same',
      );
    });

    // Insert the real user
    final me = _Player(
      name: _myName,
      initials: _myName == 'You'
          ? 'ME'
          : _myName.split(' ').map((w) => w[0]).take(2).join().toUpperCase(),
      points: myScore,
      badge: _badgeFor(myScore),
      trend: 'up',
      isMe: true,
    );

    final all = [...peers, me];
    all.sort((a, b) => b.points.compareTo(a.points));
    return all;
  }

  int _myRank(List<_Player> list) {
    final idx = list.indexWhere((p) => p.isMe);
    return idx == -1 ? list.length : idx + 1;
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════

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
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Leaderboard",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            Text(
              "لوحة الشرف",
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: goldColor,
                height: 1.3,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: accentColor,
          labelColor: accentColor,
          unselectedLabelColor: textTertiary,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
          tabs: const [
            Tab(text: "City"),
            Tab(text: "National"),
            Tab(text: "Global"),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: accentColor,
                backgroundColor: accentColor.withOpacity(0.15),
              ),
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _LeaderboardTab(
                  players: _cityList,
                  myRank: _cityRank > 0 ? _cityRank : _myRank(_cityList),
                  myPoints: _myPoints,
                  myStreak: _myStreak,
                  myPrayers: _myPrayers,
                  myDhikr: _myDhikr,
                  myVerified: _myVerified,
                  myName: _myName,
                  crownAnim: _crownAnim,
                  bgColor: bgColor,
                  cardColor: cardColor,
                  cardAltColor: cardAltColor,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textTertiary: textTertiary,
                  borderColor: borderColor,
                  btnTextColor: btnTextColor,
                  isDark: isDark,
                ),
                _LeaderboardTab(
                  players: _nationalList,
                  myRank: _nationalRank > 0
                      ? _nationalRank
                      : _myRank(_nationalList),
                  myPoints: _myPoints,
                  myStreak: _myStreak,
                  myPrayers: _myPrayers,
                  myDhikr: _myDhikr,
                  myVerified: _myVerified,
                  myName: _myName,
                  crownAnim: _crownAnim,
                  bgColor: bgColor,
                  cardColor: cardColor,
                  cardAltColor: cardAltColor,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textTertiary: textTertiary,
                  borderColor: borderColor,
                  btnTextColor: btnTextColor,
                  isDark: isDark,
                ),
                _LeaderboardTab(
                  players: _globalList,
                  myRank: _globalRank > 0 ? _globalRank : _myRank(_globalList),
                  myPoints: _myPoints,
                  myStreak: _myStreak,
                  myPrayers: _myPrayers,
                  myDhikr: _myDhikr,
                  myVerified: _myVerified,
                  myName: _myName,
                  crownAnim: _crownAnim,
                  bgColor: bgColor,
                  cardColor: cardColor,
                  cardAltColor: cardAltColor,
                  accentColor: accentColor,
                  goldColor: goldColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textTertiary: textTertiary,
                  borderColor: borderColor,
                  btnTextColor: btnTextColor,
                  isDark: isDark,
                ),
              ],
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  LEADERBOARD TAB
// ═══════════════════════════════════════════════════════════════════

class _LeaderboardTab extends StatelessWidget {
  final List<_Player> players;
  final int myRank, myPoints, myStreak, myPrayers, myDhikr, myVerified;
  final String myName;
  final Animation<double> crownAnim;
  final Color bgColor, cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      btnTextColor;
  final bool isDark;

  const _LeaderboardTab({
    required this.players,
    required this.myRank,
    required this.myPoints,
    required this.myStreak,
    required this.myPrayers,
    required this.myDhikr,
    required this.myVerified,
    required this.myName,
    required this.crownAnim,
    required this.bgColor,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.btnTextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Center(
        child: Text(
          "No data available",
          style: TextStyle(fontFamily: 'Poppins', color: textSecondary),
        ),
      );
    }

    final top3 = players.take(3).toList();
    final rest = players.skip(3).toList();
    final maxPts = players.first.points.toDouble().clamp(1.0, 99999.0);

    return Stack(
      children: [
        CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Podium ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _Podium(
                top3: top3,
                crownAnim: crownAnim,
                accentColor: accentColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textTertiary: textTertiary,
                borderColor: borderColor,
                btnTextColor: btnTextColor,
                isDark: isDark,
              ),
            ),

            // ── Score breakdown ────────────────────────────────────
            SliverToBoxAdapter(
              child: _ScoreBreakdown(
                streak: myStreak,
                prayers: myPrayers,
                dhikr: myDhikr,
                verified: myVerified,
                total: myPoints,
                cardColor: cardColor,
                cardAltColor: cardAltColor,
                accentColor: accentColor,
                goldColor: goldColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                textTertiary: textTertiary,
                borderColor: borderColor,
              ),
            ),

            // ── Rank 4+ list ───────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  if (i >= rest.length) return null;
                  final p = rest[i];
                  final rank = i + 4;
                  return _PlayerTile(
                    player: p,
                    rank: rank,
                    maxPts: maxPts,
                    cardColor: cardColor,
                    accentColor: accentColor,
                    goldColor: goldColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    textTertiary: textTertiary,
                    borderColor: borderColor,
                    btnTextColor: btnTextColor,
                  );
                }, childCount: rest.length),
              ),
            ),
          ],
        ),

        // ── Pinned "Your Rank" card ────────────────────────────────
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: _MyRankCard(
            rank: myRank,
            points: myPoints,
            name: myName,
            badge: _badgeFor(myPoints),
            accentColor: accentColor,
            goldColor: goldColor,
            btnTextColor: btnTextColor,
            borderColor: borderColor,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PODIUM
// ═══════════════════════════════════════════════════════════════════

class _Podium extends StatelessWidget {
  final List<_Player> top3;
  final Animation<double> crownAnim;
  final Color accentColor,
      goldColor,
      textPrimary,
      textTertiary,
      borderColor,
      btnTextColor;
  final bool isDark;

  const _Podium({
    required this.top3,
    required this.crownAnim,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.borderColor,
    required this.btnTextColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox(height: 16);

    // Order: 2nd | 1st | 3rd
    final order = [top3[1], top3[0], top3[2]];
    final ranks = [2, 1, 3];
    final heights = [80.0, 100.0, 70.0]; // podium column heights

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          3,
          (i) => _PodiumSlot(
            player: order[i],
            rank: ranks[i],
            colHeight: heights[i],
            crownAnim: crownAnim,
            accentColor: accentColor,
            goldColor: goldColor,
            textPrimary: textPrimary,
            textTertiary: textTertiary,
            btnTextColor: btnTextColor,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  final _Player player;
  final int rank;
  final double colHeight;
  final Animation<double> crownAnim;
  final Color accentColor, goldColor, textPrimary, textTertiary, btnTextColor;
  final bool isDark;

  const _PodiumSlot({
    required this.player,
    required this.rank,
    required this.colHeight,
    required this.crownAnim,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textTertiary,
    required this.btnTextColor,
    required this.isDark,
  });

  Color get _rankColor => rank == 1
      ? const Color(0xFFFFD700)
      : rank == 2
      ? const Color(0xFFC0C0C0)
      : const Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarR = isFirst ? 34.0 : 26.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown or medal
        if (isFirst)
          AnimatedBuilder(
            animation: crownAnim,
            builder: (_, child) =>
                Transform.scale(scale: crownAnim.value, child: child),
            child: Icon(
              Icons.emoji_events_rounded,
              color: _rankColor,
              size: 34,
            ),
          )
        else
          Icon(Icons.workspace_premium_rounded, color: _rankColor, size: 24),

        const SizedBox(height: 6),

        // Avatar + rank badge
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              width: avatarR * 2 + 6,
              height: avatarR * 2 + 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isFirst
                      ? [const Color(0xFFFFD700), const Color(0xFFFFA000)]
                      : [
                          _rankColor.withOpacity(0.40),
                          _rankColor.withOpacity(0.15),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            CircleAvatar(
              radius: avatarR,
              backgroundColor: isFirst
                  ? const Color(0xFFFFD700).withOpacity(0.20)
                  : accentColor.withOpacity(0.12),
              child: Text(
                player.isMe ? 'ME' : player.initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: isFirst ? 16 : 13,
                  fontWeight: FontWeight.w800,
                  color: isFirst ? const Color(0xFFFFD700) : accentColor,
                ),
              ),
            ),
            Positioned(
              bottom: -8,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: _rankColor,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Name
        SizedBox(
          width: 90,
          child: Text(
            player.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: player.isMe ? accentColor : textPrimary,
            ),
          ),
        ),

        const SizedBox(height: 5),

        // Points pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _rankColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _rankColor.withOpacity(0.30), width: 0.8),
          ),
          child: Text(
            '${player.points} pts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _rankColor,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Podium column
        Container(
          width: isFirst ? 72 : 56,
          height: colHeight,
          decoration: BoxDecoration(
            color: _rankColor.withOpacity(0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: _rankColor.withOpacity(0.25), width: 0.8),
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _rankColor.withOpacity(0.50),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SCORE BREAKDOWN  (what makes up the user's real points)
// ═══════════════════════════════════════════════════════════════════

class _ScoreBreakdown extends StatelessWidget {
  final int streak, prayers, dhikr, verified, total;
  final Color cardColor, cardAltColor, accentColor, goldColor;
  final Color textPrimary, textSecondary, textTertiary, borderColor;

  const _ScoreBreakdown({
    required this.streak,
    required this.prayers,
    required this.dhikr,
    required this.verified,
    required this.total,
    required this.cardColor,
    required this.cardAltColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final sources = [
      _ScoreSource(
        "Salah Streak",
        streak * 10,
        AppTheme.colorWarning,
        Icons.local_fire_department_rounded,
        "×10 per day",
      ),
      _ScoreSource(
        "Prayers Logged",
        prayers * 5,
        AppTheme.colorSuccess,
        Icons.mosque_rounded,
        "×5 per prayer",
      ),
      _ScoreSource(
        "Mosque Edits",
        total - streak * 10 - prayers * 5 - dhikr ~/ 10 - verified * 15,
        AppTheme.colorInfo,
        Icons.edit_rounded,
        "Barakah pts",
      ),
      _ScoreSource(
        "Verifications",
        verified * 15,
        AppTheme.colorSuccess,
        Icons.verified_rounded,
        "×15 per confirm",
      ),
      _ScoreSource(
        "Dhikr Count",
        dhikr ~/ 10,
        const Color(0xFF9C6FD6),
        Icons.blur_circular_rounded,
        "÷10",
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: goldColor.withOpacity(0.20), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  "Your Score Breakdown",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    "$total pts",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sources
                .where((s) => s.pts > 0)
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: s.color.withOpacity(0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 13, color: s.color),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    s.label,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      color: textPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "+${s.pts}",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: s.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(3),
                                      child: LinearProgressIndicator(
                                        value: total == 0 ? 0 : s.pts / total,
                                        minHeight: 4,
                                        backgroundColor: borderColor,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              s.color.withOpacity(0.50),
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.formula,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 9,
                                      color: textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSource {
  final String label, formula;
  final int pts;
  final Color color;
  final IconData icon;
  const _ScoreSource(this.label, this.pts, this.color, this.icon, this.formula);
}

// ═══════════════════════════════════════════════════════════════════
//  PLAYER TILE (rank 4+)
// ═══════════════════════════════════════════════════════════════════

class _PlayerTile extends StatelessWidget {
  final _Player player;
  final int rank;
  final double maxPts;
  final Color cardColor, accentColor, goldColor;
  final Color textPrimary,
      textSecondary,
      textTertiary,
      borderColor,
      btnTextColor;

  const _PlayerTile({
    required this.player,
    required this.rank,
    required this.maxPts,
    required this.cardColor,
    required this.accentColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.btnTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = _badgeColor(player.badge);
    final isMe = player.isMe;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isMe ? accentColor.withOpacity(0.08) : cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? accentColor.withOpacity(0.40) : borderColor,
          width: isMe ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          // Rank number
          SizedBox(
            width: 32,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isMe ? accentColor : textTertiary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: isMe
                ? accentColor.withOpacity(0.15)
                : accentColor.withOpacity(0.08),
            child: Text(
              isMe ? 'ME' : player.initials,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isMe ? accentColor : accentColor.withOpacity(0.70),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Name + badge + progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMe ? accentColor : textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: badgeColor.withOpacity(0.25),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        player.badge,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (player.points / maxPts).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: borderColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isMe ? accentColor : accentColor.withOpacity(0.40),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Trend
                Row(
                  children: [
                    Icon(
                      player.trend == 'up'
                          ? Icons.arrow_upward_rounded
                          : player.trend == 'down'
                          ? Icons.arrow_downward_rounded
                          : Icons.remove_rounded,
                      size: 12,
                      color: player.trend == 'up'
                          ? AppTheme.colorSuccess
                          : player.trend == 'down'
                          ? AppTheme.colorError
                          : textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      player.trend == 'up'
                          ? 'Rising'
                          : player.trend == 'down'
                          ? 'Falling'
                          : 'Stable',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: player.trend == 'up'
                            ? AppTheme.colorSuccess
                            : player.trend == 'down'
                            ? AppTheme.colorError
                            : textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Points
          Text(
            '${player.points}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isMe ? accentColor : textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            ' pts',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              color: textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MY RANK CARD  (pinned at bottom)
// ═══════════════════════════════════════════════════════════════════

class _MyRankCard extends StatelessWidget {
  final int rank, points;
  final String name, badge;
  final Color accentColor, goldColor, btnTextColor, borderColor;

  const _MyRankCard({
    required this.rank,
    required this.points,
    required this.name,
    required this.badge,
    required this.accentColor,
    required this.goldColor,
    required this.btnTextColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name == 'You'
        ? 'ME'
        : name.split(' ').map((w) => w[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: btnTextColor.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: btnTextColor.withOpacity(0.25),
                width: 0.8,
              ),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: btnTextColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: btnTextColor.withOpacity(0.20),
            child: Text(
              initials,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: btnTextColor,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Name + badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: btnTextColor,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: btnTextColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: btnTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: btnTextColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: btnTextColor.withOpacity(0.70),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
