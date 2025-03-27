import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/services/api_service.dart';
import 'package:flutter/rendering.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({Key? key}) : super(key: key);

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> myCourses = [];
  List<Map<String, dynamic>> availableCourses = [];
  bool isLoading = true;
  final String baseUrl =
      'http://172.20.10.14:8888/api'; // Ajustez selon votre configuration
  int? userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    initializeDateFormatting('fr_FR', null).then((_) {
      _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      print('Données utilisateur: $userString');

      if (userString != null) {
        final userData = json.decode(userString);
        print('ID utilisateur: ${userData['id']}');

        if (mounted) {
          setState(() {
            userId = userData['id'];
          });
        }
        await _loadCourses();
      } else {
        print('Aucune donnée utilisateur trouvée');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: $e');
    }
  }

  Future<void> _loadCourses() async {
    try {
      setState(() => isLoading = true);

      // Ajout de logs pour le débogage
      print('Chargement des cours pour userId: $userId');

      // Modification des URLs pour correspondre à l'API
      final myCoursesData =
          await ApiService.get('/cours/get_my_courses.php?user_id=$userId');
      print('Réponse mes cours: $myCoursesData');

      final availableCoursesData =
          await ApiService.get('/cours/get_available_courses.php?user_id=$userId');
      print('Réponse cours disponibles: $availableCoursesData');

      if (mounted) {
        setState(() {
          // Vérification plus précise de la structure des données
          if (myCoursesData != null && myCoursesData['courses'] != null) {
            myCourses =
                List<Map<String, dynamic>>.from(myCoursesData['courses']);
            print('Nombre de mes cours: ${myCourses.length}');
          } else {
            myCourses = [];
            print('Aucun cours trouvé dans mes cours');
          }

          if (availableCoursesData != null &&
              availableCoursesData['courses'] != null) {
            availableCourses = List<Map<String, dynamic>>.from(
                availableCoursesData['courses']);
            print('Nombre de cours disponibles: ${availableCourses.length}');
          } else {
            availableCourses = [];
            print('Aucun cours disponible trouvé');
          }
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des cours: $e');
      if (e.toString().contains('Token invalide') ||
          e.toString().contains('Non autorisé')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      }
      if (mounted) {
        setState(() {
          myCourses = [];
          availableCourses = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _subscribeToCourse(int courseId) async {
    try {
      final response = await ApiService.post('/cours/subscribe_course.php', {
        'user_id': userId,
        'course_id': courseId,
      });

      if (response['success']) {
        _showSuccessAlert('Inscription réussie !');
        _loadCourses();
      } else {
        _showErrorAlert(response['message'] ?? 'Erreur d\'inscription');
      }
    } catch (e) {
      print('Erreur d\'inscription: $e');
      _showErrorAlert('Erreur lors de l\'inscription');
    }
  }

  void _showSuccessAlert(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Succès'),
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

  void _showErrorAlert(String message) {
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

  Future<void> _unsubscribeFromCourse(int courseId) async {
    try {
      final response = await ApiService.post('/cours/unsubscribe_course.php', {
        'user_id': userId,
        'course_id': courseId,
      });

      if (response['success']) {
        _showSuccessAlert('Désinscription réussie !');
        _loadCourses();
      } else {
        _showErrorAlert(response['message'] ?? 'Erreur de désinscription');
      }
    } catch (e) {
      print('Erreur de désinscription: $e');
      _showErrorAlert('Erreur lors de la désinscription');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.04;
    final double cardWidth = screenWidth * 0.92;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Séances',
          style: TextStyle(
            fontSize: screenWidth < 380 ? 17 : 20,
            fontWeight: FontWeight.w600,
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
            },
            child: const Icon(
              CupertinoIcons.arrow_clockwise_circle_fill,
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
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Container(
                width: cardWidth,
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.systemGrey6.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CupertinoSlidingSegmentedControl<int>(
                    children: {
                      0: _buildSegmentContent(
                          'Mes séances',
                          CupertinoIcons.calendar_circle_fill,
                          _tabController.index == 0),
                      1: _buildSegmentContent(
                          'À venir',
                          CupertinoIcons.calendar_badge_plus,
                          _tabController.index == 1),
                    },
                    groupValue: _tabController.index,
                    onValueChanged: (int? index) {
                      if (index != null) {
                        HapticFeedback.selectionClick();
                        setState(() => _tabController.index = index);
                      }
                    },
                    backgroundColor: CupertinoColors.systemBackground,
                  ),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildPageContent(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentContent(String text, IconData icon, bool isSelected) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.35, // Largeur fixe
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.systemGrey,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 14),
          const SizedBox(height: 16),
          Text(
            'Chargement de vos séances...',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 16,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalPadding = screenWidth * 0.04;
    final double cardWidth = screenWidth * 0.92;

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: IndexedStack(
          index: _tabController.index,
          children: [
            _buildCoursesList(
              myCourses,
              isSubscribed: true,
              horizontalPadding: horizontalPadding,
              cardWidth: cardWidth,
            ),
            _buildCoursesList(
              availableCourses,
              isSubscribed: false,
              horizontalPadding: horizontalPadding,
              cardWidth: cardWidth,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(
    List<Map<String, dynamic>> courses, {
    required bool isSubscribed,
    required double horizontalPadding,
    required double cardWidth,
  }) {
    if (courses.isEmpty) {
      return _buildEmptyState(isSubscribed: isSubscribed);
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        String formattedDate;
        try {
          final courseDate =
              DateTime.now(); // On utilise la date du jour comme base
          formattedDate = DateFormat('EEEE', 'fr_FR').format(courseDate) +
              ' ' +
              (course['jour'] ?? 'Non défini');
        } catch (e) {
          formattedDate = course['jour'] ?? 'Date non définie';
        }

        // Vérification de sécurité pour l'horaire
        final horaire = course['horaire'] ?? '00:00 - 00:00';
        final heureDebut = horaire.split(' - ')[0];
        final horaireParts = heureDebut.split(':');

        // Vérification que nous avons des valeurs valides
        final heure = int.tryParse(horaireParts[0]) ?? 0;
        final minute = int.tryParse(horaireParts[1]) ?? 0;

        final courseDate = DateTime.now().copyWith(hour: heure, minute: minute);
        final formattedTime = heureDebut;

        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.systemGrey6.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: CupertinoColors.activeBlue.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          formattedTime,
                          style: TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['titre'],
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Description', course['description']),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          'Places', '${course['nombre_inscrits']} inscrits'),
                      const SizedBox(height: 16),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => isSubscribed
                            ? _showUnsubscribeDialog(course['id'])
                            : _subscribeToCourse(course['id']),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSubscribed
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.activeBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSubscribed ? 'Se désinscrire' : 'S\'inscrire',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            color: CupertinoColors.label,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel,
              fontSize: 15,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({required bool isSubscribed}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSubscribed
                ? CupertinoIcons.calendar_badge_minus
                : CupertinoIcons.search,
            size: 48,
            color: CupertinoColors.secondaryLabel,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune séance à venir',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSubscribed
                ? 'Vous n\'êtes inscrit à aucun cours'
                : 'Aucun cours disponible pour le moment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showUnsubscribeDialog(int courseId) async {
    return showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Voulez-vous vraiment vous désinscrire de ce cours ?'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Confirmer'),
              onPressed: () {
                Navigator.of(context).pop();
                _unsubscribeFromCourse(courseId);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
