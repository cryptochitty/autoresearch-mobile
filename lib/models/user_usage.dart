class UserUsage {
  final String userId;
  final int requestsToday;
  final String lastResetDate;
  final bool isPremium;

  const UserUsage({
    required this.userId,
    required this.requestsToday,
    required this.lastResetDate,
    required this.isPremium,
  });

  static const int freeLimit = 5;

  bool get canMakeRequest => isPremium || requestsToday < freeLimit;
  int get remainingFreeRequests => (freeLimit - requestsToday).clamp(0, freeLimit);

  factory UserUsage.fromMap(Map<String, dynamic> map) {
    return UserUsage(
      userId: map['userId'] ?? '',
      requestsToday: map['requestsToday'] ?? 0,
      lastResetDate: map['lastResetDate'] ?? '',
      isPremium: map['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'requestsToday': requestsToday,
    'lastResetDate': lastResetDate,
    'isPremium': isPremium,
  };
}
