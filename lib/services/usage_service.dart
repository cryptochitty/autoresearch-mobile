import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_usage.dart';

class UsageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<UserUsage> getUsage(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();

    if (!doc.exists) {
      final usage = UserUsage(
        userId: userId,
        requestsToday: 0,
        lastResetDate: _todayString(),
        isPremium: false,
      );
      await _db.collection('users').doc(userId).set(usage.toMap());
      return usage;
    }

    final data = doc.data()!;
    final usage = UserUsage.fromMap({...data, 'userId': userId});

    // Reset daily count if it's a new day
    if (usage.lastResetDate != _todayString()) {
      final reset = UserUsage(
        userId: userId,
        requestsToday: 0,
        lastResetDate: _todayString(),
        isPremium: usage.isPremium,
      );
      await _db.collection('users').doc(userId).update(reset.toMap());
      return reset;
    }

    return usage;
  }

  Future<void> incrementUsage(String userId) async {
    await _db.collection('users').doc(userId).update({
      'requestsToday': FieldValue.increment(1),
    });
  }

  Future<void> setPremium(String userId, bool isPremium) async {
    await _db.collection('users').doc(userId).update({
      'isPremium': isPremium,
    });
  }
}
