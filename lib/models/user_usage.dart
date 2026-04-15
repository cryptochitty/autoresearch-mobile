class UserUsage {
  final String userId;
  final int papersViewed;
  final int papersDownloaded;
  final String lastResetDate;
  final String lastDownloadResetMonth;
  final bool isPremium;

  const UserUsage({
    required this.userId,
    required this.papersViewed,
    required this.papersDownloaded,
    required this.lastResetDate,
    required this.lastDownloadResetMonth,
    required this.isPremium,
  });

  static const int freeViewLimit = 1;        // per day
  static const int premiumDownloadLimit = 3; // per month

  bool get canViewPaper => isPremium || papersViewed < freeViewLimit;
  bool get canDownloadPaper => isPremium && papersDownloaded < premiumDownloadLimit;

  int get remainingDownloads =>
      (premiumDownloadLimit - papersDownloaded).clamp(0, premiumDownloadLimit);

  factory UserUsage.fromMap(Map<String, dynamic> map) {
    return UserUsage(
      userId: map['userId'] ?? '',
      papersViewed: map['papersViewed'] ?? 0,
      papersDownloaded: map['papersDownloaded'] ?? 0,
      lastResetDate: map['lastResetDate'] ?? '',
      lastDownloadResetMonth: map['lastDownloadResetMonth'] ?? '',
      isPremium: map['isPremium'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'papersViewed': papersViewed,
    'papersDownloaded': papersDownloaded,
    'lastResetDate': lastResetDate,
    'lastDownloadResetMonth': lastDownloadResetMonth,
    'isPremium': isPremium,
  };
}
