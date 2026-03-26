import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────
// FIRESTORE SCHEMA
// ─────────────────────────────────────────────────────────────────
//
// Collection: users
// Document:   {uid}
// Fields:
//   displayName       String   — from Firebase Auth
//   email             String
//   city              String   — "Karachi", "London" etc (set on first sync)
//   country           String   — "Pakistan", "UK" etc
//
//   points            int      — composite leaderboard score
//   barakahPoints     int      — mosque edit points only
//   streak            int      — daily prayer streak
//   prayersLogged     int
//   dhikrCount        int
//   mosqueVerifications int
//   niyyahCount       int
//   khushuScore       int      — 0-100
//
//   lastUpdated       Timestamp
//   createdAt         Timestamp
//
// Security rules (paste into Firebase console):
//   match /users/{uid} {
//     allow read:  if true;                        // public leaderboard reads
//     allow write: if request.auth.uid == uid;     // only owner can write
//   }
// ─────────────────────────────────────────────────────────────────

// ── Event types ────────────────────────────────────────────────────
enum PointEvent {
  mosqueEdit, // +5 per time field, +2 per facility
  mosqueVerification, // +15
  prayerLogged, // +5
  streakDay, // +10
  dhikrTap, // +1 (stored raw, ÷10 in score)
  niyyahAdded, // +3
  khushuUpdate, // not points — updates khushu field
}

// ── Leaderboard entry ──────────────────────────────────────────────
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int points;
  final String badge;
  final String city;
  final String country;
  final bool isMe;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.points,
    required this.badge,
    required this.city,
    required this.country,
    this.isMe = false,
  });
}

// ─────────────────────────────────────────────────────────────────
// POINTS SERVICE
// ─────────────────────────────────────────────────────────────────

class PointsService {
  PointsService._();
  static final PointsService instance = PointsService._();

  // ── Firestore + Auth refs ─────────────────────────────────────
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Prefs keys ────────────────────────────────────────────────
  static const _kBarakah = 'barakah_points';
  static const _kStreak = 'companion_streak';
  static const _kPrayers = 'companion_prayers_logged';
  static const _kDhikr = 'companion_dhikr';
  static const _kKhushu = 'companion_khushu';
  static const _kNiyyah = 'niyyah_vault';
  static const _kVerify = 'my_verify_votes';
  static const _kDirtyDelta = 'points_dirty_delta'; // pending Firestore sync
  static const _kUserCity = 'user_city';
  static const _kUserCountry = 'user_country';

  // ── Retry timer ───────────────────────────────────────────────
  Timer? _retryTimer;

  // ─────────────────────────────────────────────────────────────
  //  WRITE  (local-first, non-blocking Firestore sync)
  // ─────────────────────────────────────────────────────────────

  /// Call this from every point-earning action in the app.
  /// Returns immediately after updating SharedPreferences.
  /// Firestore is updated in the background.
  Future<void> award(PointEvent event, {int amount = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── 1. Apply locally ───────────────────────────────────────
      switch (event) {
        case PointEvent.mosqueEdit:
          final cur = prefs.getInt(_kBarakah) ?? 0;
          await prefs.setInt(_kBarakah, cur + amount);
          break;
        case PointEvent.mosqueVerification:
          // Handled by nearby_mosque_screen — we just record for score
          break;
        case PointEvent.prayerLogged:
          final cur = prefs.getInt(_kPrayers) ?? 0;
          await prefs.setInt(_kPrayers, cur + 1);
          break;
        case PointEvent.streakDay:
          final cur = prefs.getInt(_kStreak) ?? 0;
          await prefs.setInt(_kStreak, cur + 1);
          break;
        case PointEvent.dhikrTap:
          final cur = prefs.getInt(_kDhikr) ?? 0;
          await prefs.setInt(_kDhikr, cur + 1);
          break;
        case PointEvent.niyyahAdded:
          // Stored in niyyah_vault list — no separate counter needed
          break;
        case PointEvent.khushuUpdate:
          if (amount >= 0 && amount <= 100) {
            await prefs.setInt(_kKhushu, amount);
          }
          break;
      }

      // ── 2. Mark dirty delta for retry ─────────────────────────
      // We store the raw increment so failed syncs can be retried exactly
      if (event != PointEvent.khushuUpdate) {
        final dirty = prefs.getInt(_kDirtyDelta) ?? 0;
        final pts = _pointsFor(event, amount: amount, prefs: prefs);
        if (pts > 0) await prefs.setInt(_kDirtyDelta, dirty + pts);
      }

      // ── 3. Sync to Firestore (background) ─────────────────────
      _syncToFirestore(prefs);
    } catch (e) {
      debugPrint("PointsService.award error: $e");
    }
  }

  // ── Calculate composite score from all local values ───────────
  int computeTotalScore(SharedPreferences prefs) {
    final barakah = prefs.getInt(_kBarakah) ?? 0;
    final streak = prefs.getInt(_kStreak) ?? 0;
    final prayers = prefs.getInt(_kPrayers) ?? 0;
    final dhikr = prefs.getInt(_kDhikr) ?? 0;
    final niyyahs = (prefs.getStringList(_kNiyyah) ?? []).length;
    final verified = (prefs.getStringList(_kVerify) ?? []).length;

    return barakah +
        streak * 10 +
        prayers * 5 +
        dhikr ~/ 10 +
        verified * 15 +
        niyyahs * 3;
  }

  int _pointsFor(
    PointEvent event, {
    int amount = 0,
    required SharedPreferences prefs,
  }) {
    switch (event) {
      case PointEvent.mosqueEdit:
        return amount;
      case PointEvent.mosqueVerification:
        return 15;
      case PointEvent.prayerLogged:
        return 5;
      case PointEvent.streakDay:
        return 10;
      case PointEvent.dhikrTap:
        return 0; // dhikr ÷10 already in compute
      case PointEvent.niyyahAdded:
        return 3;
      case PointEvent.khushuUpdate:
        return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  FIRESTORE SYNC
  // ─────────────────────────────────────────────────────────────

  Future<void> _syncToFirestore(SharedPreferences prefs) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return; // not signed in — skip

    try {
      final totalScore = computeTotalScore(prefs);
      final user = _auth.currentUser!;

      final data = <String, dynamic>{
        'displayName': user.displayName ?? 'User',
        'email': user.email ?? '',
        'points': totalScore,
        'barakahPoints': prefs.getInt(_kBarakah) ?? 0,
        'streak': prefs.getInt(_kStreak) ?? 0,
        'prayersLogged': prefs.getInt(_kPrayers) ?? 0,
        'dhikrCount': prefs.getInt(_kDhikr) ?? 0,
        'khushuScore': prefs.getInt(_kKhushu) ?? 0,
        'mosqueVerifications': (prefs.getStringList(_kVerify) ?? []).length,
        'niyyahCount': (prefs.getStringList(_kNiyyah) ?? []).length,
        'city': prefs.getString(_kUserCity) ?? '',
        'country': prefs.getString(_kUserCountry) ?? '',
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await _db
          .collection('users')
          .doc(uid)
          .set(
            data,
            SetOptions(merge: true), // never overwrite fields we didn't set
          );

      // ── Clear dirty flag on success ───────────────────────────
      await prefs.setInt(_kDirtyDelta, 0);
      _retryTimer?.cancel();
    } catch (e) {
      debugPrint("Firestore sync error: $e");
      // ── Schedule retry in 60 seconds ──────────────────────────
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 60), () async {
        try {
          final p = await SharedPreferences.getInstance();
          await _syncToFirestore(p);
        } catch (_) {}
      });
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  READ — full sync on app start
  // ─────────────────────────────────────────────────────────────

  /// Call once in initState of the root widget or after sign-in.
  /// Downloads Firestore data and hydrates local prefs.
  /// Falls back to local data if offline.
  Future<void> syncFromFirestore() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists) {
        // First time — push local data up
        final prefs = await SharedPreferences.getInstance();
        await _syncToFirestore(prefs);
        return;
      }

      final d = doc.data()!;
      final prefs = await SharedPreferences.getInstance();

      // Only overwrite local if Firestore value is higher
      // (protects against stale cloud data after offline edits)
      final cloudPts = (d['barakahPoints'] as int?) ?? 0;
      final cloudStrk = (d['streak'] as int?) ?? 0;
      final cloudPray = (d['prayersLogged'] as int?) ?? 0;
      final cloudDhkr = (d['dhikrCount'] as int?) ?? 0;
      final cloudKhsh = (d['khushuScore'] as int?) ?? 0;

      final localPts = prefs.getInt(_kBarakah) ?? 0;
      final localStrk = prefs.getInt(_kStreak) ?? 0;
      final localPray = prefs.getInt(_kPrayers) ?? 0;
      final localDhkr = prefs.getInt(_kDhikr) ?? 0;
      final localKhsh = prefs.getInt(_kKhushu) ?? 0;

      await prefs.setInt(_kBarakah, cloudPts > localPts ? cloudPts : localPts);
      await prefs.setInt(
        _kStreak,
        cloudStrk > localStrk ? cloudStrk : localStrk,
      );
      await prefs.setInt(
        _kPrayers,
        cloudPray > localPray ? cloudPray : localPray,
      );
      await prefs.setInt(
        _kDhikr,
        cloudDhkr > localDhkr ? cloudDhkr : localDhkr,
      );
      await prefs.setInt(
        _kKhushu,
        cloudKhsh > localKhsh ? cloudKhsh : localKhsh,
      );

      // Save city/country if not set locally
      if ((prefs.getString(_kUserCity) ?? '').isEmpty) {
        final city = (d['city'] as String?) ?? '';
        final country = (d['country'] as String?) ?? '';
        if (city.isNotEmpty) await prefs.setString(_kUserCity, city);
        if (country.isNotEmpty) await prefs.setString(_kUserCountry, country);
      }

      // If we had local dirty changes, push the merged result up
      final dirty = prefs.getInt(_kDirtyDelta) ?? 0;
      if (dirty > 0) await _syncToFirestore(prefs);
    } catch (e) {
      debugPrint("syncFromFirestore error (using local): $e");
      // Graceful fallback — local data still works
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  LEADERBOARD QUERIES
  // ─────────────────────────────────────────────────────────────

  /// Fetch top-N users for the given scope.
  /// scope: 'city' | 'country' | 'global'
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required String scope,
    int limit = 20,
  }) async {
    final uid = _auth.currentUser?.uid;
    final prefs = await SharedPreferences.getInstance();
    final myCity = prefs.getString(_kUserCity) ?? '';
    final myCntry = prefs.getString(_kUserCountry) ?? '';

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('users')
          .orderBy('points', descending: true);

      if (scope == 'city' && myCity.isNotEmpty) {
        query = query.where('city', isEqualTo: myCity);
      } else if (scope == 'country' && myCntry.isNotEmpty) {
        query = query.where('country', isEqualTo: myCntry);
      }
      // 'global' — no filter

      final snap = await query.limit(limit).get();

      return snap.docs.map((doc) {
        final d = doc.data();
        final pts = (d['points'] as int?) ?? 0;
        return LeaderboardEntry(
          uid: doc.id,
          displayName: (d['displayName'] as String?) ?? 'User',
          points: pts,
          badge: _badgeFor(pts),
          city: (d['city'] as String?) ?? '',
          country: (d['country'] as String?) ?? '',
          isMe: doc.id == uid,
        );
      }).toList();
    } catch (e) {
      debugPrint("fetchLeaderboard($scope) error: $e");
      return []; // graceful empty — UI handles it
    }
  }

  /// Fetch the current user's own rank for a given scope.
  Future<int> fetchMyRank({required String scope}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 0;

    final prefs = await SharedPreferences.getInstance();
    final myPts = computeTotalScore(prefs);
    final myCity = prefs.getString(_kUserCity) ?? '';
    final myCntry = prefs.getString(_kUserCountry) ?? '';

    try {
      Query<Map<String, dynamic>> query = _db
          .collection('users')
          .where('points', isGreaterThan: myPts);

      if (scope == 'city' && myCity.isNotEmpty) {
        query = query.where('city', isEqualTo: myCity);
      } else if (scope == 'country' && myCntry.isNotEmpty) {
        query = query.where('country', isEqualTo: myCntry);
      }

      final snap = await query.count().get();
      return (snap.count ?? 0) + 1; // rank = people ahead of me + 1
    } catch (e) {
      debugPrint("fetchMyRank error: $e");
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  USER PROFILE
  // ─────────────────────────────────────────────────────────────

  /// Set city/country once (after sign-up or from settings).
  Future<void> setLocation({
    required String city,
    required String country,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kUserCity, city);
      await prefs.setString(_kUserCountry, country);

      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _db.collection('users').doc(uid).set({
          'city': city,
          'country': country,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("setLocation error: $e");
    }
  }

  // ─────────────────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────────────────

  static String _badgeFor(int pts) {
    if (pts >= 500) return 'Ummah Builder';
    if (pts >= 200) return 'Mosque Guardian';
    if (pts >= 100) return 'Mosque Keeper';
    if (pts >= 50) return 'Helper';
    if (pts >= 10) return 'Contributor';
    return 'New Helper';
  }

  void dispose() {
    _retryTimer?.cancel();
  }
}
