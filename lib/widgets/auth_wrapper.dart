import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../pages/login_page.dart';

class AuthWrapper extends StatefulWidget {
  final Widget child;

  const AuthWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTokenCheck();
  }

  void _startTokenCheck() {
    // Vérification toutes les 10 secondes
    _timer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final isValid = await ApiService.verifyToken();
      if (!isValid && mounted) {
        // Si le token n'est plus valide, rediriger vers la page de connexion
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
