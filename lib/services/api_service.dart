import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import '/pages/login_page.dart';
import 'auth_navigator.dart';

class ApiService {
  static Timer? _tokenCheckTimer;
  static bool _isCheckingToken = false;
  static const String baseUrl = 'http://172.20.10.14:8888/api';

  static void startTokenCheck(BuildContext context) {
    _tokenCheckTimer?.cancel(); // Annuler le timer existant s'il y en a un

    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_isCheckingToken) return; // Éviter les vérifications simultanées
      _isCheckingToken = true;

      try {
        final isValid = await verifyToken();
        print('Vérification du token: ${isValid ? 'valide' : 'invalide'}');

        if (!isValid) {
          _tokenCheckTimer?.cancel();
          // Vérifier si le contexte est toujours valide
          if (context.mounted) {
            // Afficher le dialogue de session expirée
            showCupertinoDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Session expirée'),
                content: const Text(
                    'Votre session a expiré. Veuillez vous reconnecter.'),
                actions: [
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () async {
                      // Nettoyer les données de session
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();

                      if (context.mounted) {
                        // Rediriger vers la page de login
                        Navigator.of(context, rootNavigator: true)
                            .pushReplacementNamed('/login');
                      }
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      } finally {
        _isCheckingToken = false;
      }
    });
  }

  static void stopTokenCheck() {
    _tokenCheckTimer?.cancel();
    _tokenCheckTimer = null;
  }

  static Future<void> _handleInvalidToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Déconnexion - Nettoyage des données...');
      await prefs.clear();
      print('Redirection vers la page de connexion...');
      AuthNavigator.logout();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  static Future<bool> verifyToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('Vérification du token dans SharedPreferences: $token');

      if (token == null || token.isEmpty) {
        print('Token non trouvé');
        await AuthNavigator.logout();
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/verify_token.php'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': token}),
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] == true;

        if (!isValid) {
          print('Token invalide: ${data['message']}');
          await AuthNavigator.logout();
        }
        return isValid;
      }

      await AuthNavigator.logout();
      return false;
    } catch (e) {
      print('Erreur de vérification du token: $e');
      await AuthNavigator.logout();
      return false;
    }
  }

  // regarder si le token et bien pris en compte + vérification
  static Future<bool> _checkTokenBeforeRequest() async {
    try {
      return await verifyToken();
    } catch (e) {
      print('Erreur lors de la vérification du token avant requête: $e');
      return false;
    }
  }

  static Future<String> getTokenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final loginTime = prefs.getString('loginTime');

      if (token == null) return 'Aucun token trouvé';

      return '''
Token: ${token.substring(0, min(20, token.length))}...
Login Time: $loginTime
''';
    } catch (e) {
      return 'Erreur lors de la récupération des informations: $e';
    }
  }

  // Obtenir les headers avec le token
  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final url = '$baseUrl/login/login.php';
      print('Tentative de connexion à l\'URL: $url'); // Log de l'URL

      final requestBody = {
        'email': email,
        'password': password,
      };
      print('Données envoyées: $requestBody'); // Log des données envoyées

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Status code: ${response.statusCode}'); // Log du status code
      print(
          'Réponse brute du serveur: ${response.body}'); // Log de la réponse complète

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Données décodées: $data'); // Log des données décodées
          return data;
        } catch (e) {
          print('Erreur de décodage JSON: $e'); // Log de l'erreur de décodage
          throw FormatException(
              'Réponse invalide du serveur: ${response.body}');
        }
      } else {
        throw Exception(
            'Erreur serveur: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erreur complète: $e'); // Log de toute erreur
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token non trouvé');
      }

      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        // Token invalide ou expiré
        await prefs.clear(); // efface donnée stocker
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur API: $e');
      rethrow;
    }
  }

  // POST avec token
  static Future<dynamic> post(String endpoint, dynamic data) async {
    if (!await verifyToken()) {
      throw Exception('Token invalide');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 401) {
      await AuthNavigator.logout();
      throw Exception('Non autorisé');
    }

    return jsonDecode(response.body);
  }

  // Gestion des réponses
  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      _handleUnauthorized();
      throw Exception('Non autorisé');
    } else {
      throw Exception('Erreur ${response.statusCode}: ${response.body}');
    }
  }

  // Gestion de l'expiration du token
  static void _handleUnauthorized() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    // Note: La navigation vers login sera gérée par le widget parent
  }

  
}
