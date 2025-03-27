import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGeneratingLicense = false;
  bool _isAutoLicence = false;

  late AnimationController _animationController;

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeIn,
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _niveauController = TextEditingController();
  final TextEditingController _dateNaissanceController =
      TextEditingController();
  final TextEditingController _licenceFFEController = TextEditingController();
  final TextEditingController _villeController = TextEditingController();

  // Variables pour les sélections
  Map<String, dynamic>? _selectedVille;
  Map<String, dynamic>? _selectedNiveau;
  List<Map<String, dynamic>> _villesSuggestions = [];
  List<Map<String, dynamic>> _niveaux = [];
  bool _isSearchingVille = false;

  // Couleurs modernes style iOS
  static const Color primaryColor = Color(0xFF007AFF);
  static const Color backgroundColor = Color(0xFFF2F2F7);
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF1C1C1E);
  static const Color subtitleColor = Color(0xFF8E8E93);
  static const Color errorColor = Color(0xFFFF3B30);
  static const Color successColor = Color(0xFF34C759);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadNiveaux();
  }

  @override
  void dispose() {
    if (mounted) {
      _animationController.dispose();
    }
    _emailController.dispose();
    _passwordController.dispose();
    _nomController.dispose();
    _prenomController.dispose();
    _telephoneController.dispose();
    _niveauController.dispose();
    _dateNaissanceController.dispose();
    _licenceFFEController.dispose();
    _villeController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _formKey.currentState?.reset();
      _animationController
        ..reset()
        ..forward();
    });
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isLogin = true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNiveaux() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/get_niveaux.php'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Niveaux chargés: ${data['niveaux']}'); // Debug log
        setState(() {
          _niveaux = List<Map<String, dynamic>>.from(data['niveaux']);
        });
      }
    } catch (e) {
      print('Erreur chargement niveaux: $e');
    }
  }

  Future<void> _searchVilles(String query) async {
    if (query.length < 2) {
      setState(() => _villesSuggestions = []);
      return;
    }

    setState(() => _isSearchingVille = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/autocomp/search_ville.php?q=$query'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _villesSuggestions = List<Map<String, dynamic>>.from(data['results']);
          _isSearchingVille = false;
        });
      }
    } catch (e) {
      print('Erreur recherche villes: $e');
      setState(() => _isSearchingVille = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        DateTime selectedDate = DateTime.now();
        return Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Annuler'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(selectedDate),
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime:
                      DateTime.now().subtract(const Duration(days: 365 * 18)),
                  maximumDate: DateTime.now(),
                  minimumYear: 1900,
                  maximumYear: DateTime.now().year,
                  onDateTimeChanged: (DateTime newDate) {
                    selectedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateNaissanceController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 40),
              _buildForm(),
              const SizedBox(height: 20),
              _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF5856D6),
                Color(0xFF007AFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5856D6).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.person_crop_circle_fill,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Haras des Neuilles',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Connectez-vous à votre compte' : 'Créez votre compte',
          style: const TextStyle(
            fontSize: 17,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (!_isLogin) ...[
                _buildTextField(
                  controller: _nomController,
                  label: 'Nom',
                  icon: CupertinoIcons.person,
                ),
                _buildTextField(
                  controller: _prenomController,
                  label: 'Prénom',
                  icon: CupertinoIcons.person_fill,
                ),
                _buildTextField(
                  controller: _telephoneController,
                  label: 'Téléphone',
                  icon: CupertinoIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  controller: _dateNaissanceController,
                  label: 'Date de naissance',
                  icon: CupertinoIcons.calendar,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                ),
                _buildTextField(
                  controller: _villeController,
                  label: 'Ville',
                  icon: CupertinoIcons.location,
                  onChanged: (value) => _searchVilles(value),
                ),
                if (_villesSuggestions.isNotEmpty)
                  Container(
                    height: 200,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBackground,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: CupertinoColors.systemGrey4),
                    ),
                    child: ListView.builder(
                      itemCount: _villesSuggestions.length,
                      itemBuilder: (context, index) {
                        final ville = _villesSuggestions[index];
                        return CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          onPressed: () {
                            setState(() {
                              _selectedVille = ville;
                              _villeController.text =
                                  '${ville['nom_commune']} (${ville['code_postal']})';
                              _villesSuggestions = [];
                            });
                          },
                          child: Text(
                            '${ville['nom_commune']} (${ville['code_postal']}) - ${ville['nom_departement']}',
                            style:
                                const TextStyle(color: CupertinoColors.label),
                          ),
                        );
                      },
                    ),
                  ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: _buildTextField(
                    controller: _niveauController,
                    label: 'Niveau d\'équitation',
                    icon: CupertinoIcons.star,
                    readOnly: true,
                    onTap: () {
                      if (_niveaux.isEmpty) {
                        _showError('Chargement des niveaux en cours...');
                        _loadNiveaux();
                        return;
                      }

                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 300,
                          color: CupertinoColors.systemBackground,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  CupertinoButton(
                                    child: const Text('Annuler'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  CupertinoButton(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: CupertinoPicker(
                                  itemExtent: 40,
                                  onSelectedItemChanged: (index) {
                                    setState(() {
                                      _selectedNiveau = _niveaux[index];
                                      _niveauController.text =
                                          _niveaux[index]['Galop'];
                                      print(
                                          'Niveau sélectionné: ${_niveaux[index]}'); // Debug log
                                    });
                                  },
                                  children: _niveaux.map((niveau) {
                                    return Center(
                                      child: Text(
                                        niveau['Galop'] ?? 'Niveau inconnu',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _licenceFFEController,
                              label: 'Licence FFE',
                              icon: CupertinoIcons.doc_text,
                              readOnly: _isAutoLicence,
                            ),
                          ),
                          const SizedBox(width: 10),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            color: _isAutoLicence
                                ? CupertinoColors.activeGreen
                                : CupertinoColors.systemGrey5,
                            onPressed: () {
                              setState(() {
                                _isAutoLicence = !_isAutoLicence;
                                if (_isAutoLicence) {
                                  _generateLicenceFFE();
                                } else {
                                  _licenceFFEController.clear();
                                }
                              });
                            },
                            child: _isGeneratingLicense
                                ? const CupertinoActivityIndicator()
                                : Text(
                                    _isAutoLicence ? 'Auto ✓' : 'Auto',
                                    style: TextStyle(
                                      color: _isAutoLicence
                                          ? CupertinoColors.white
                                          : CupertinoColors.label,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      if (_isAutoLicence)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Licence générée automatiquement',
                            style: TextStyle(
                              color: CupertinoColors.activeGreen,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: CupertinoIcons.mail,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildTextField(
                controller: _passwordController,
                label: 'Mot de passe',
                icon: CupertinoIcons.lock,
                obscureText: _obscurePassword,
                suffixIcon: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    color: subtitleColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    Function(String)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: label,
        prefix: Icon(
          icon,
          size: 20,
          color: CupertinoColors.activeBlue,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(
          color: CupertinoColors.label,
          fontSize: 16,
        ),
        obscureText: obscureText,
        suffix: suffixIcon,
        readOnly: readOnly,
        onTap: onTap,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF5856D6),
            Color(0xFF007AFF),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MaterialButton(
        onPressed: _isLoading ? null : _submitForm,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: _isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                _isLogin ? 'Se connecter' : 'S\'inscrire',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return CupertinoButton(
      onPressed: _toggleMode,
      child: Text(
        _isLogin
            ? 'Pas encore de compte ? S\'inscrire'
            : 'Déjà un compte ? Se connecter',
        style: const TextStyle(
          color: primaryColor,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final baseUrl = 'http://172.20.10.14:8888/api';
      final endpoint = _isLogin ? '/login/login.php' : '/login/register.php';
      final url = baseUrl + endpoint;

      print('⭐ Tentative de connexion à: $url'); // Log de l'URL complète

      final bodyData = _isLogin
          ? {
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            }
          : {
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'nom': _nomController.text.trim(),
              'prenom': _prenomController.text.trim(),
              'telephone': _telephoneController.text.trim(),
              'id_niveau': _selectedNiveau?['id'],
              'licence_ffe': _licenceFFEController.text.trim(),
              'date_naissance': _dateNaissanceController.text,
              'ville': _selectedVille?['id'],
            };

      print('📦 Données envoyées: $bodyData'); // Log des données envoyées

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(bodyData),
      );

      print('🔄 Status code: ${response.statusCode}'); // Log du code de statut
      print('📥 Réponse brute: ${response.body}'); // Log de la réponse complète

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Données décodées: $data'); // Log des données décodées

          if (data['success'] == true) {
            if (_isLogin) {
              final prefs = await SharedPreferences.getInstance();
              final userDataToStore = data['user'];
              final token = data['token'];

              print(
                  '👤 Données utilisateur: $userDataToStore'); // Log des données utilisateur
              print('🔑 Token reçu: $token'); // Log du token

              await prefs.setString('user', jsonEncode(userDataToStore));
              await prefs.setString('token', token);
              await prefs.setString(
                  'loginTime', DateTime.now().toIso8601String());

              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/main');
            } else {
              if (!mounted) return;
              _showSuccess(
                  'Inscription réussie ! Vous pouvez maintenant vous connecter');
            }
          } else {
            if (!mounted) return;
            _showError(data['message'] ?? 'Une erreur est survenue');
          }
        } catch (e) {
          print('❌ Erreur de décodage JSON: $e'); // Log des erreurs de décodage
          _showError('Erreur de format dans la réponse du serveur');
        }
      } else {
        throw Exception('Erreur de serveur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur complète: $e'); // Log de toute erreur
      if (!mounted) return;
      _showError('Erreur de connexion au serveur: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateLicenceFFE() async {
    setState(() => _isGeneratingLicense = true);

    try {
      // Format : année en cours + 6 chiffres aléatoires
      final year = DateTime.now().year.toString();
      final random = List.generate(6, (_) => (0 + Random().nextInt(9))).join();
      final newLicence = '$year$random';

      // Vérifier si la licence existe déjà
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/autocomp/check_licence.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'licence': newLicence}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['exists'] == false) {
          setState(() {
            _licenceFFEController.text = newLicence;
          });
        } else {
          // Si la licence existe, réessayer
          await _generateLicenceFFE();
        }
      }
    } catch (e) {
      print('Erreur génération licence: $e');
      _showError('Erreur lors de la génération de la licence');
    } finally {
      setState(() => _isGeneratingLicense = false);
    }
  }
}
