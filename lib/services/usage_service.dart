import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_usage.dart';

class UsageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _thisMonthString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<UserUsage> getUsage(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists) {
      final usage = UserUsage(
        userId: userId,
        papersViewed: 0,
        papersDownloaded: 0,
        lastResetDate: _todayString(),
        lastDownloadResetMonth: _thisMonthString(),
        isPremium: false,
      );
      await _db.collection('users').doc(userId).set(usage.toMap());
      return usage;
    }

    final data = doc.data()!;
    var usage = UserUsage.fromMap({...data, 'userId': userId});

    // Reset daily view count on new day
    if (usage.lastResetDate != _todayString()) {
      usage = UserUsage(
        userId: userId,
        papersViewed: 0,
        papersDownloaded: usage.papersDownloaded,
        lastResetDate: _todayString(),
        lastDownloadResetMonth: usage.lastDownloadResetMonth,
        isPremium: usage.isPremium,
      );
      await _db.collection('users').doc(userId).update({
        'papersViewed': 0,
        'lastResetDate': _todayString(),
      });
    }

    // Reset monthly download count on new month
    if (usage.lastDownloadResetMonth != _thisMonthString()) {
      usage = UserUsage(
        userId: userId,
        papersViewed: usage.papersViewed,
        papersDownloaded: 0,
        lastResetDate: usage.lastResetDate,
        lastDownloadResetMonth: _thisMonthString(),
        isPremium: usage.isPremium,
      );
      await _db.collection('users').doc(userId).update({
        'papersDownloaded': 0,
        'lastDownloadResetMonth': _thisMonthString(),
      });
    }

    return usage;
  }

  Future<void> incrementViewed(String userId) async {
    await _db.collection('users').doc(userId).update({
      'papersViewed': FieldValue.increment(1),
    });
  }

  Future<void> incrementDownloaded(String userId) async {
    await _db.collection('users').doc(userId).update({
      'papersDownloaded': FieldValue.increment(1),
    });
  }

  Future<void> setPremium(String userId, bool isPremium) async {
    await _db.collection('users').doc(userId).update({
      'isPremium': isPremium,
    });
  }
}
