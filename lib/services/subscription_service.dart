import 'package:purchases_flutter/purchases_flutter.dart';
import 'usage_service.dart';

class SubscriptionService {
  final UsageService _usageService = UsageService();

  static const String premiumMonthly = 'premium_monthly';

  Future<bool> checkPremiumStatus(String userId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final isPremium =
          customerInfo.entitlements.active.containsKey('premium');

      // Sync with Firestore
      await _usageService.setPremium(userId, isPremium);
      return isPremium;
    } catch (e) {
      return false;
    }
  }

  Future<bool> purchasePremium() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;
      if (current == null) return false;

      final package = current.monthly;
      if (package == null) return false;

      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.active.containsKey('premium');
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) return false;
      rethrow;
    }
  }

  Future<bool> restorePurchases(String userId) async {
    final customerInfo = await Purchases.restorePurchases();
    final isPremium = customerInfo.entitlements.active.containsKey('premium');
    await _usageService.setPremium(userId, isPremium);
    return isPremium;
  }
}
