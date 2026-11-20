import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;

  ProfileService._internal() {
    _loadProfile();
  }

  static const String _keyName = 'bitify_profile_name';
  static const String _keyTier = 'bitify_profile_tier';

  String _name = 'You';
  String _tier = 'Bitify Ultra • Lossless Subscriber';

  String get name => _name;
  String get tier => _tier;

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _name = prefs.getString(_keyName) ?? 'Music Lover';
      _tier = prefs.getString(_keyTier) ?? 'Bitify Ultra • Lossless Subscriber';
      notifyListeners();
    } catch (_) {}
  }

  Future<void> updateProfile({required String name, required String tier}) async {
    _name = name.trim().isEmpty ? 'Music Lover' : name.trim();
    _tier = tier.trim().isEmpty ? 'Bitify Subscriber' : tier.trim();
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyName, _name);
      await prefs.setString(_keyTier, _tier);
    } catch (_) {}
  }
}
