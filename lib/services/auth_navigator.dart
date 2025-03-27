import 'package:flutter/material.dart';
import '../pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }
}
