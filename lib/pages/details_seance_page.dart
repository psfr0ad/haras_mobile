import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class DetailsSeancePage extends StatelessWidget {
  final Map<String, dynamic> seance;

  const DetailsSeancePage({
    Key? key,
    required this.seance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.parse(seance['date'] ?? DateTime.now().toIso8601String());
    final formattedDate = DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
    final formattedTime = DateFormat('HH:mm', 'fr_FR').format(date);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Détails de la séance'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                seance['titre'] ?? 'Séance',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.label,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                title: 'Informations',
                children: [
                  _buildInfoRow(
                    icon: CupertinoIcons.clock,
                    label: 'Heure',
                    value: formattedTime,
                  ),
                  _buildInfoRow(
                    icon: CupertinoIcons.person_2,
                    label: 'Moniteur',
                    value: seance['moniteur'] ?? 'Non spécifié',
                  ),
                  _buildInfoRow(
                    icon: CupertinoIcons.paw,
                    label: 'Cheval',
                    value: seance['cheval_nom'] ?? 'Non spécifié',
                  ),
                  _buildInfoRow(
                    icon: CupertinoIcons.group,
                    label: 'Niveau',
                    value: seance['niveau'] ?? 'Non spécifié',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                title: 'Description',
                children: [
                  Text(
                    seance['description'] ?? 'Aucune description',
                    style: TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
              if (seance['commentaires'] != null) ...[
                const SizedBox(height: 24),
                _buildInfoSection(
                  title: 'Commentaires',
                  children: [
                    Text(
                      seance['commentaires'],
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }
}
