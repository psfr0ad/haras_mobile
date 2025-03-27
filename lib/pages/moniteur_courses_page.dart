import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class MoniteurCoursesPage extends StatefulWidget {
  const MoniteurCoursesPage({Key? key}) : super(key: key);

  @override
  State<MoniteurCoursesPage> createState() => _MoniteurCoursesPageState();
}

class _MoniteurCoursesPageState extends State<MoniteurCoursesPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> allSeances = [];
  Map<String, dynamic>? userData;
  String selectedFilter = 'Toutes';
  final String baseUrl = 'http://172.20.10.14:8888:8888/api';

  final List<String> filterOptions = [
    'Toutes',
    'Mes séances',
    'Disponibles',
    'Cette semaine',
    'Mois prochain'
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadUserData();
      _loadAllSeances();
    });
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
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadAllSeances() async {
    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        final response = await http.post(
          Uri.parse('$baseUrl/get_all_seances.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'moniteur_id': userId.toString()}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            setState(() {
              allSeances = List<Map<String, dynamic>>.from(data['seances']);
              isLoading = false;
            });
          } else {
            setState(() {
              allSeances = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            allSeances = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des séances: $e');
      setState(() {
        isLoading = false;
        allSeances = [];
      });
    }
  }

  Future<void> _inscriptionSeance(int seanceId) async {
    if (userData == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscrire_moniteur_seance.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'moniteur_id': userData!['id'].toString(),
          'seance_id': seanceId.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog(
              'Inscription réussie', 'Vous êtes inscrit à cette séance.');
          _loadAllSeances();
        } else {
          _showErrorDialog(
              'Erreur',
              data['message'] ??
                  'Une erreur est survenue lors de l\'inscription.');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        _showErrorDialog('Erreur', 'Erreur de connexion au serveur.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de l\'inscription: $e');
      _showErrorDialog(
          'Erreur', 'Une erreur est survenue lors de l\'inscription.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _desinscriptionSeance(int seanceId) async {
    if (userData == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/desinscrire_moniteur_seance.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'moniteur_id': userData!['id'].toString(),
          'seance_id': seanceId.toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog('Désinscription réussie',
              'Vous êtes désinscrit de cette séance.');
          _loadAllSeances();
        } else {
          _showErrorDialog(
              'Erreur',
              data['message'] ??
                  'Une erreur est survenue lors de la désinscription.');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        _showErrorDialog('Erreur', 'Erreur de connexion au serveur.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la désinscription: $e');
      _showErrorDialog(
          'Erreur', 'Une erreur est survenue lors de la désinscription.');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _inscriptionCours(Map<String, dynamic> seance) async {
    if (userData == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/inscrire_moniteur_cours.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'moniteur_id': userData!['id'].toString(),
          'cours_id': seance['cours_id'].toString(),
          'seance_id': seance['seance_id'].toString(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          _showSuccessDialog(
            'Inscription réussie',
            'Vous êtes inscrit à toutes les séances de ce cours pour l\'année.',
          );
          _loadAllSeances();
        } else {
          _showErrorDialog(
            'Erreur',
            data['message'] ??
                'Une erreur est survenue lors de l\'inscription.',
          );
        }
      } else {
        _showErrorDialog('Erreur', 'Erreur de connexion au serveur.');
      }
    } catch (e) {
      print('Erreur lors de l\'inscription au cours: $e');
      _showErrorDialog(
        'Erreur',
        'Une erreur est survenue lors de l\'inscription.',
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showSuccessDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredSeances() {
    if (selectedFilter == 'Toutes') {
      return allSeances;
    } else if (selectedFilter == 'Mes séances') {
      return allSeances
          .where((seance) => seance['est_inscrit'] == true)
          .toList();
    } else if (selectedFilter == 'Disponibles') {
      return allSeances
          .where((seance) => seance['est_inscrit'] != true)
          .toList();
    } else if (selectedFilter == 'Cette semaine') {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      return allSeances.where((seance) {
        try {
          final seanceDate = DateTime.parse(seance['date_seance']);
          return seanceDate.isAfter(startOfWeek) &&
              seanceDate.isBefore(endOfWeek);
        } catch (e) {
          return false;
        }
      }).toList();
    } else if (selectedFilter == 'Mois prochain') {
      final now = DateTime.now();
      final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
      final endOfNextMonth = DateTime(now.year, now.month + 2, 0);

      return allSeances.where((seance) {
        try {
          final seanceDate = DateTime.parse(seance['date_seance']);
          return seanceDate.isAfter(startOfNextMonth) &&
              seanceDate.isBefore(endOfNextMonth);
        } catch (e) {
          return false;
        }
      }).toList();
    }

    return allSeances;
  }

  @override
  Widget build(BuildContext context) {
    final filteredSeances = _getFilteredSeances();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Gestion des séances',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
        trailing: GestureDetector(
          onTap: _loadAllSeances,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              CupertinoIcons.refresh,
              color: CupertinoColors.activeBlue,
              size: 20,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.slider_horizontal_3,
                        color: CupertinoColors.activeBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filtre',
                        style: TextStyle(
                          color: CupertinoColors.activeBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CupertinoSlidingSegmentedControl<String>(
                          groupValue: selectedFilter,
                          onValueChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedFilter = value;
                              });
                            }
                          },
                          children: {
                            for (var option in filterOptions.take(3))
                              option: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : filteredSeances.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredSeances.length,
                          itemBuilder: (context, index) {
                            return _buildSeanceCard(filteredSeances[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(75),
            ),
            child: Icon(
              CupertinoIcons.calendar_badge_minus,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune séance trouvée',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              selectedFilter == 'Toutes'
                  ? 'Il n\'y a pas de séances disponibles actuellement.'
                  : 'Aucune séance ne correspond à ce filtre.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeanceCard(Map<String, dynamic> seance) {
    String formattedDate;
    try {
      final seanceDate = DateTime.parse(seance['date_seance']);
      formattedDate =
          DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(seanceDate);
    } catch (e) {
      formattedDate = seance['date_seance'] ?? 'Date non définie';
    }

    final bool estInscrit = seance['est_inscrit'] == true;
    final String heureDebut = seance['HD'] ?? '00:00';
    final String heureFin = seance['HF'] ?? '00:00';
    final String statusText = estInscrit ? 'Inscrit' : 'Disponible';
    final Color statusColor =
        estInscrit ? CupertinoColors.activeGreen : CupertinoColors.activeBlue;

    void _showInscriptionConfirmation() {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Confirmation d\'inscription'),
          content: const Text(
            'Voulez-vous vous inscrire à toutes les séances de ce cours pour l\'année ?\n\n'
            'Cette action vous inscrira automatiquement à toutes les séances hebdomadaires.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context);
                _inscriptionCours(seance);
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      seance['Libcours'] ?? 'Séance',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$heureDebut - $heureFin',
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.person_2,
                      size: 16,
                      color: CupertinoColors.secondaryLabel,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      seance['moniteur'] ?? 'Moniteur non assigné',
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              if (estInscrit) {
                _showDesincriptionConfirmation(seance);
              } else {
                _showInscriptionConfirmation();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: estInscrit
                    ? CupertinoColors.systemRed.withOpacity(0.1)
                    : CupertinoColors.activeGreen.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    estInscrit
                        ? CupertinoIcons.minus_circle
                        : CupertinoIcons.check_mark_circled,
                    color: estInscrit
                        ? CupertinoColors.systemRed
                        : CupertinoColors.activeGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    estInscrit ? 'Se désinscrire' : 'S\'inscrire',
                    style: TextStyle(
                      color: estInscrit
                          ? CupertinoColors.systemRed
                          : CupertinoColors.activeGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDesincriptionConfirmation(Map<String, dynamic> seance) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
            'Êtes-vous sûr de vouloir vous désinscrire de cette séance ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _desinscriptionSeance(seance['seance_id']);
            },
            child: const Text('Désinscrire'),
          ),
        ],
      ),
    );
  }
}
