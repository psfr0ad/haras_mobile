import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '/services/api_service.dart';

class TokenMonitorPage extends StatefulWidget {
  const TokenMonitorPage({Key? key}) : super(key: key);

  @override
  State<TokenMonitorPage> createState() => _TokenMonitorPageState();
}

class _TokenMonitorPageState extends State<TokenMonitorPage> {
  Timer? _timer;
  bool _isValid = true;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  Future<void> _startMonitoring() async {
    // Vérification initiale
    await _checkToken();

    // Vérification toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (mounted) {
        await _checkToken();
      }
    });
  }

  Future<void> _checkToken() async {
    try {
      final isValid = await ApiService.verifyToken();
      if (mounted) {
        setState(() {
          _isValid = isValid;
        });
      }
    } catch (e) {
      print('Erreur dans _checkToken: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Moniteur de Token'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Statut du token: ${_isValid ? 'Valide' : 'Invalide'}',
                style: TextStyle(
                  color: _isValid
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.destructiveRed,
                  fontSize: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
