import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('à propos'),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAppInfo(),
              const SizedBox(height: 20),
              _buildDeveloperInfo(),
              const SizedBox(height: 20),
              _buildLegalInfo(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return _buildCard(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      CupertinoColors.systemBlue.withOpacity(0.8),
                      CupertinoColors.activeBlue.withOpacity(0.9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CupertinoColors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.paw,
                    size: 45,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Centre Équestre',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gérez vos séances d\'équitation',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeveloperInfo() {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow(
            'Développé par',
            'Léonard Bonnet',
            icon: CupertinoIcons.person_fill,
          ),
          _buildDivider(),
          _buildInfoRow(
            'Contact',
            'leonard.bonnet@example.com',
            icon: CupertinoIcons.mail_solid,
          ),
          _buildDivider(),
          _buildInfoRow(
            'Site web',
            'www.centreequestre.com',
            icon: CupertinoIcons.globe,
            isLink: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfo() {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow(
            'Conditions d\'utilisation',
            '',
            icon: CupertinoIcons.doc_text_fill,
            showChevron: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            'Politique de confidentialité',
            '',
            icon: CupertinoIcons.shield_fill,
            showChevron: true,
          ),
          _buildDivider(),
          _buildInfoRow(
            'Licences',
            '',
            icon: CupertinoIcons.doc_fill,
            showChevron: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.08),
            blurRadius: 30,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: CupertinoColors.systemGrey6.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    IconData? icon,
    bool isLink = false,
    bool showChevron = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: showChevron || isLink ? () {} : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isLink
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.label,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (value.isNotEmpty) ...[
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.secondaryLabel.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            if (showChevron) ...[
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.systemGrey3,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 0.5,
        color: CupertinoColors.separator.withOpacity(0.5),
      ),
    );
  }
}
