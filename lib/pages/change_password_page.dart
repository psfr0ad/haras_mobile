import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Ajout des contrôleurs de focus pour gérer l'animation
  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_validateInputs()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Debug des données utilisateur
      print('Données utilisateur brutes: $userString');

      final userData = json.decode(userString);
      print('Données utilisateur décodées: $userData');

      // Vérifier toutes les clés possibles pour l'email
      String? email;
      if (userData is Map) {
        email = userData['mail'] ??
            userData['email'] ??
            userData['Mail'] ??
            userData['Email'] ??
            userData['utilisateur']
                ?['mail'] ?? // Vérifier dans un sous-objet 'utilisateur'
            userData['user']?['mail']; // Vérifier dans un sous-objet 'user'
      }

      if (email == null) {
        print('Structure des données utilisateur: ${userData.runtimeType}');
        throw Exception(
            'Email non trouvé dans les données utilisateur: $userData');
      }

      print('Email trouvé: $email'); // Debug

      final requestBody = {
        'email': email,
        'current_password': _currentPasswordController.text.trim(),
        'new_password': _newPasswordController.text.trim(),
      };

      print('Données envoyées: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('http://172.20.10.14:8888/api/password/change_password.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('Status code: ${response.statusCode}');
      print('Réponse du serveur brute: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          print('Données décodées: $data');

          if (data['success'] == true) {
            if (mounted) {
              _showSuccessDialog();
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
            }
          } else {
            setState(() {
              _errorMessage = data['message'] == 'Mot de passe actuel incorrect'
                  ? 'Le mot de passe actuel est incorrect. Veuillez réessayer.'
                  : data['message'] ?? 'Une erreur est survenue';
            });
          }
        } catch (e) {
          print('Erreur de décodage JSON: $e');
          setState(() {
            _errorMessage = 'Erreur de format de réponse';
          });
        }
      } else {
        throw Exception('Erreur de serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur lors du changement de mot de passe: $e');
      setState(() {
        _errorMessage = 'Erreur de connexion au serveur. Veuillez réessayer.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Ajoutez cette méthode pour déboguer les données utilisateur
  void _debugUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      final userData = json.decode(userString);
      print('Données utilisateur stockées: $userData');
    } else {
      print('Aucune donnée utilisateur trouvée');
    }
  }

  @override
  void initState() {
    super.initState();
    // Déboguer les données utilisateur au chargement
    _debugUserData();
  }

  bool _validateInputs() {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs';
      });
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Les nouveaux mots de passe ne correspondent pas';
      });
      return false;
    }

    if (_newPasswordController.text.length < 6) {
      setState(() {
        _errorMessage =
            'Le nouveau mot de passe doit contenir au moins 6 caractères';
      });
      return false;
    }

    if (!_isPasswordComplex(_newPasswordController.text)) {
      setState(() {
        _errorMessage =
            'Le mot de passe doit contenir au moins une majuscule, une minuscule et un chiffre';
      });
      return false;
    }

    return true;
  }

  bool _isPasswordComplex(String password) {
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    return hasUppercase && hasLowercase && hasDigits;
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: const Text(
            'Votre mot de passe a été modifié avec succès. Veuillez vous reconnecter.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              // Effacer les données de l'utilisateur
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); // Supprime toutes les données stockées

              // Fermer le dialogue et naviguer vers la page de connexion
              Navigator.of(context).popUntil((route) => route.isFirst);
              Navigator.of(context).pushReplacementNamed(
                  '/login'); // Assurez-vous que votre route de login est bien nommée '/login'
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Sécurité',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 30),
              _buildPasswordSection(),
              if (_errorMessage != null) _buildErrorMessage(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 20),
              _buildSecurityTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.lock_shield_fill,
              color: CupertinoColors.activeBlue,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Modifier votre mot de passe',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assurez-vous d\'utiliser un mot de passe fort et unique',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPasswordField(
            controller: _currentPasswordController,
            focusNode: _currentFocus,
            placeholder: 'Mot de passe actuel',
            obscureText: _obscureCurrentPassword,
            onToggleVisibility: () {
              setState(
                  () => _obscureCurrentPassword = !_obscureCurrentPassword);
            },
            icon: CupertinoIcons.lock_circle_fill,
            isFirst: true,
          ),
          _buildDivider(),
          _buildPasswordField(
            controller: _newPasswordController,
            focusNode: _newFocus,
            placeholder: 'Nouveau mot de passe',
            obscureText: _obscureNewPassword,
            onToggleVisibility: () {
              setState(() => _obscureNewPassword = !_obscureNewPassword);
            },
            icon: CupertinoIcons.lock_shield_fill,
          ),
          _buildDivider(),
          _buildPasswordField(
            controller: _confirmPasswordController,
            focusNode: _confirmFocus,
            placeholder: 'Confirmer le mot de passe',
            obscureText: _obscureConfirmPassword,
            onToggleVisibility: () {
              setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword);
            },
            icon: CupertinoIcons.check_mark_circled_solid,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String placeholder,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required IconData icon,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: CupertinoColors.activeBlue,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              placeholder: placeholder,
              obscureText: obscureText,
              decoration: null,
              style: const TextStyle(fontSize: 16),
              placeholderStyle: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 16,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.all(4),
            onPressed: onToggleVisibility,
            child: Icon(
              obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: CupertinoColors.separator.withOpacity(0.5),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.destructiveRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: CupertinoColors.destructiveRed.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle_fill,
            color: CupertinoColors.destructiveRed,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: CupertinoColors.destructiveRed,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: CupertinoButton.filled(
          onPressed: _isLoading ? null : _changePassword,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.checkmark_shield_fill),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Mettre à jour le mot de passe',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Conseils de sécurité',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipItem(
            'Utilisez au moins 8 caractères',
            CupertinoIcons.textformat_size,
          ),
          _buildTipItem(
            'Incluez des caractères spéciaux',
            CupertinoIcons.number_circle_fill,
          ),
          _buildTipItem(
            'Mélangez majuscules et minuscules',
            CupertinoIcons.textformat_abc,
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel,
                fontSize: 14,
              ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
