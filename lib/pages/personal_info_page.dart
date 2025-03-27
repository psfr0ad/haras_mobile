import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/services/api_service.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({Key? key}) : super(key: key);

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        setState(() {
          userData = json.decode(userString);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('informations personnelles'),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildContactCard(),
                      const SizedBox(height: 20),
                      _buildAccountCard(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return _buildCard(
      'informations cavalier',
      [
        _buildInfoRow('nom', userData?['nom'] ?? '-'),
        _buildInfoRow('prénom', userData?['prenom'] ?? '-'),
        _buildInfoRow('niveau', userData?['niveau_galop'] ?? '-'),
        _buildInfoRow('licence ffe', userData?['licence_ffe'] ?? '-'),
        _buildInfoRow('date de naissance', userData?['date_naissance'] ?? '-'),
      ],
    );
  }

  Widget _buildContactCard() {
    return _buildCard(
      'contact',
      [
        _buildInfoRow('email', userData?['email'] ?? '-'),
        _buildInfoRow('téléphone', userData?['telephone'] ?? '-'),
        _buildInfoRow('adresse', userData?['adresse'] ?? '-'),
        _buildInfoRow('code postal', userData?['code_postal'] ?? '-'),
        _buildInfoRow('ville', userData?['ville'] ?? '-'),
      ],
    );
  }

  Widget _buildAccountCard() {
    return _buildCard(
      'compte',
      [
        _buildInfoRow('identifiant', '${userData?['id'] ?? '-'}'),
        _buildInfoRow(
          'type de compte',
          userData?['id_role'] == 2 ? 'cavalier' : 'administrateur',
        ),
        _buildInfoRow(
          'date d\'inscription',
          userData?['date_inscription'] ?? '-',
        ),
      ],
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.separator.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.separator.withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              CupertinoIcons.calendar,
              color: CupertinoColors.activeBlue,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
