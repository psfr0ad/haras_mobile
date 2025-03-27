import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'personal_info_page.dart';
import 'about_page.dart';
import 'change_password_page.dart';
import 'token_monitor_page.dart';
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, dynamic>? userData;

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
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
    }
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Déconnexion'),
          content: const Text(
            'Voulez-vous vraiment vous déconnecter de votre compte ?',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context);
                _logout(context);
              },
              child: const Text('Déconnexion'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Paramètres'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection(),
                    const SizedBox(height: 35),
                    _buildSection(
                      'Compte',
                      [
                        _buildSettingItem(
                          context,
                          'Informations personnelles',
                          CupertinoIcons.person_fill,
                          showChevron: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const PersonalInfoPage(),
                              ),
                            );
                          },
                        ),
                        _buildSettingItem(
                          context,
                          'Changer le mot de passe',
                          CupertinoIcons.lock_fill,
                          showChevron: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) =>
                                    const ChangePasswordPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    _buildSection(
                      'Application',
                      [
                        _buildSettingItem(
                          context,
                          'Notifications',
                          CupertinoIcons.bell_fill,
                          showChevron: true,
                          onTap: () {},
                        ),
                        _buildSettingItem(
                          context,
                          'Langue',
                          CupertinoIcons.globe,
                          subtitle: 'Français',
                          showChevron: true,
                          onTap: () {},
                        ),
                        _buildSettingItem(
                          context,
                          'À propos',
                          CupertinoIcons.info_circle_fill,
                          showChevron: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const AboutPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    _buildSection(
                      'Moniteur de Token',
                      [
                        _buildSettingItem(
                          context,
                          'Moniteur de Token',
                          CupertinoIcons.timer,
                          showChevron: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const TokenMonitorPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 35),
                    _buildSection(
                      '',
                      [
                        _buildSettingItem(
                          context,
                          'Déconnexion',
                          CupertinoIcons.square_arrow_right,
                          isDestructive: true,
                          showChevron: false,
                          onTap: () => _showLogoutConfirmation(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              CupertinoColors.secondaryLabel.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.activeBlue,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userData?['prenom'] ?? ''} ${userData?['nom'] ?? ''}'
                      .trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cavalier · ${userData?['niveau'] ?? ''}',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials() {
    final prenom = userData?['prenom'] as String? ?? '';
    final nom = userData?['nom'] as String? ?? '';
    return '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'
        .toUpperCase();
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
                letterSpacing: 0.5,
              ),
            ),
          ),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    String title,
    IconData icon, {
    String? subtitle,
    bool isDestructive = false,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDestructive
                    ? CupertinoColors.destructiveRed.withOpacity(0.1)
                    : CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isDestructive
                    ? CupertinoColors.destructiveRed
                    : CupertinoColors.activeBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      color: isDestructive
                          ? CupertinoColors.destructiveRed
                          : CupertinoColors.label,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              const Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey2,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
