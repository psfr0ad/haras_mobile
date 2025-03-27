import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'details_seance_page.dart';
import '/services/api_service.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> upcomingSessions = [];
  bool isLoading = true;
  String? userName;
  Map<String, dynamic> userStats = {
    'heures_cumulees': 0,
    'niveau': 'Débutant',
    'progression': 0.0,
  };

  final String baseUrl = 'http://172.20.10.14:8888/api';

  @override
  void initState() {
    super.initState();
    _checkToken();
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadUserData();
      _loadUpcomingSessions();
      _loadUserStats();
    });
  }

  Future<void> _checkToken() async {
    await ApiService.verifyToken();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        setState(() {
          userName = userData['prenom'];
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadUpcomingSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      print('=== DÉBUT DU CHARGEMENT DES SÉANCES ===');
      print('UserString: $userString');

      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        print('UserId: $userId');
        print('URL appelée: $baseUrl/calendrier/get_seances_cavalier.php');

        final requestBody = json.encode({
          'user_id': userId.toString(),
        });
        print('Corps de la requête: $requestBody');

        final response = await http.post(
          Uri.parse('$baseUrl/calendrier/get_seances_cavalier.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: requestBody,
        );

        print('Status code: ${response.statusCode}');
        print('Réponse brute: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Data décodée: $data');

          if (data['success'] == true) {
            final seances = data['seances'] as List<dynamic>;
            print('Nombre de séances reçues: ${seances.length}');

            setState(() {
              upcomingSessions = List<Map<String, dynamic>>.from(seances);
              if (data.containsKey('seances')) {
                upcomingSessions =
                    List<Map<String, dynamic>>.from(data['seances']);
                print('Séances chargées: $upcomingSessions');
              } else if (data.containsKey('sessions')) {
                upcomingSessions =
                    List<Map<String, dynamic>>.from(data['sessions']);
                print('Sessions chargées: $upcomingSessions');
              }
              print('Nombre de séances chargées: ${upcomingSessions.length}');
              isLoading = false;
            });
          } else {
            print('Erreur retournée par l\'API: ${data['message']}');
            setState(() {
              upcomingSessions = [];
              isLoading = false;
            });
          }
        } else {
          print('Erreur HTTP: ${response.statusCode}');
          setState(() {
            upcomingSessions = [];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des séances: $e');
      setState(() {
        isLoading = false;
        upcomingSessions = [];
      });
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        final response = await http.post(
          Uri.parse('$baseUrl/get_user_stats.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'user_id': userId.toString()}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            setState(() {
              userStats = data['stats'];
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      // Utiliser ApiService pour les requêtes
      final response = await ApiService.get('sessions.php');
      // Traiter la réponse...
    } catch (e) {
      if (e.toString().contains('Token invalide')) {
        // Rediriger vers la page de login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Accueil',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
            border: null,
            trailing: Container(
              decoration: BoxDecoration(
                color: CupertinoColors.activeBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() => isLoading = true);
                  _loadUserData();
                  _loadUpcomingSessions();
                },
                child: const Icon(
                  CupertinoIcons.arrow_clockwise_circle_fill,
                  color: CupertinoColors.activeBlue,
                  size: 20,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildWelcomeCard(),
                  const SizedBox(height: 24),
                  _buildUserStats(),
                  const SizedBox(height: 24),
                  _buildUpcomingSessionsHeader(),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 14),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (upcomingSessions.isEmpty) {
                          return _buildEmptyState();
                        }
                        final sessions = upcomingSessions.take(5).toList();
                        if (index >= sessions.length) return null;

                        final isLastItem = index == sessions.length - 1;
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: isLastItem ? 100 : 12,
                          ),
                          child: _buildSessionCard(sessions[index]),
                        );
                      },
                      childCount: upcomingSessions.isEmpty
                          ? 1
                          : upcomingSessions.take(5).length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.activeBlue.withOpacity(0.9),
                CupertinoColors.systemBlue.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.activeBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: CupertinoColors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_crop_circle_fill,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour,',
                          style: TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.white.withOpacity(0.9),
                          ),
                        ),
                        Text(
                          userName ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: CupertinoColors.systemGrey5.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre progression',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: CupertinoIcons.clock_fill,
                title: 'Heures',
                value: '${userStats['heures_cumulees']}h',
              ),
              Container(
                width: 1,
                height: 40,
                color: CupertinoColors.systemGrey5.withOpacity(0.5),
              ),
              _buildStatItem(
                icon: CupertinoIcons.star_fill,
                title: 'Niveau',
                value: userStats['niveau'],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: userStats['progression'],
              backgroundColor: CupertinoColors.systemGrey6,
              valueColor: AlwaysStoppedAnimation<Color>(
                CupertinoColors.activeBlue,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: CupertinoColors.activeBlue,
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingSessionsHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Vos prochaines séances',
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width < 380 ? 20 : 24,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${upcomingSessions.take(5).length} séances',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 380 ? 15 : 17,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.calendar_badge_minus,
            size: 48,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune séance à venir',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Consultez la page des cours pour vous inscrire à de nouvelles séances',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    String formattedDate;
    try {
      final sessionDate = DateTime.parse(session['date_seance']);
      formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(sessionDate);
    } catch (e) {
      print('Erreur de parsing de date: $e');
      formattedDate = session['date_seance'] ?? 'Date non définie';
    }

    // Afficher les détails de la session pour débogage
    print('Contenu de la session: ${session.toString()}');

    final heureDebut = session['HD'] ?? '00:00';
    final estInscrit = session['est_inscrit'] == true;

    // Récupérer le nom du cheval avec plusieurs alternatives possibles
    String chevalNom = 'Non assigné';
    if (session.containsKey('cheval_nom') && session['cheval_nom'] != null) {
      chevalNom = session['cheval_nom'];
    } else if (session.containsKey('nom_cheval') &&
        session['nom_cheval'] != null) {
      chevalNom = session['nom_cheval'];
    } else if (session.containsKey('cheval') && session['cheval'] != null) {
      chevalNom = session['cheval'];
    }

    final niveauCours = session['niveau'] ?? 'Non spécifié';
    final niveauCavalier = userStats['niveau'] ?? 'Débutant';
    final estNiveauAdapte = niveauCours == niveauCavalier;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: CupertinoColors.systemGrey5.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.all(16),
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => DetailsSeancePage(seance: session),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        heureDebut,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${session['duree'] ?? '60'}min',
                        style: const TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['Libcours'] ?? 'Séance',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.secondaryLabel,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.paw,
                                size: 14,
                                color: CupertinoColors.secondaryLabel,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  chevalNom,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: estNiveauAdapte
                                ? CupertinoColors.activeGreen.withOpacity(0.15)
                                : CupertinoColors.activeOrange
                                    .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            niveauCours,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: estNiveauAdapte
                                  ? CupertinoColors.activeGreen
                                  : CupertinoColors.activeOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: CupertinoColors.systemGrey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
