import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/rendering.dart';
import 'dart:ui'; // Ajoutez cet import pour ImageFilter
import 'package:flutter/services.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool isLoading = true;
  final String baseUrl = 'http://172.20.10.14:8888/api/calendrier';

  // Ajout des contrôleurs manquants
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  bool _isRefreshing = false;
  final double _refreshTriggerPullDistance = 100.0;
  bool _showFloatingButton = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_scrollListener);
    _loadSessions();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.offset > 200 && !_showFloatingButton) {
      setState(() => _showFloatingButton = true);
    } else if (_scrollController.offset <= 200 && _showFloatingButton) {
      setState(() => _showFloatingButton = false);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    HapticFeedback.selectionClick();
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    await _loadSessions();
    setState(() => _isRefreshing = false);
  }

  Future<void> _loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        final response = await http.post(
          Uri.parse('$baseUrl/get_seances_cavalier.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({'user_id': userId.toString()}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Réponse API complète: ${response.body}'); // Ajout de log
          if (data['success'] == true) {
            final seances = data['seances'] as List<dynamic>;
            // Vérifions les données de chaque séance
            for (var seance in seances) {
              print(
                  'Séance: ${seance['seance_id']}, Cheval: ${seance['cheval_nom']}, ID Cheval: ${seance['cheval_id']}');
            }
            _processEvents(seances);
          }
        }
      }
      setState(() => isLoading = false);
    } catch (e) {
      print('Erreur lors du chargement des séances: $e');
      setState(() => isLoading = false);
    }
  }

  void _processEvents(List<dynamic> seances) {
    Map<DateTime, List<dynamic>> events = {};
    for (var seance in seances) {
      try {
        final date = DateTime.parse(seance['date_seance']);
        final dateKey = DateTime(date.year, date.month, date.day);

        if (events[dateKey] == null) {
          events[dateKey] = [];
        }
        events[dateKey]!.add(seance);
        print(
            'Ajout séance pour ${dateKey.toString()}: ${seance['Libcours']}'); // Pour le débogage
      } catch (e) {
        print('Erreur lors du traitement de la séance: $e');
      }
    }
    setState(() => _events = events);
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  Future<void> _unsubscribeFromSession(Map<String, dynamic> session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      // Debug
      print(
          'Tentative de désinscription pour la séance: ${session['seance_id']}');
      print('Session complète: $session');

      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        final response = await http.post(
          Uri.parse('$baseUrl/desinscrire_seance.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'user_id': userId.toString(),
            'seance_id': session['seance_id']
                .toString(), // Assurez-vous que c'est le bon ID
          }),
        );

        print('Réponse du serveur: ${response.body}'); // Debug

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['success'] == true) {
            await _loadSessions(); // Recharger les séances
            if (mounted) {
              _showSuccessMessage('Désinscription réussie');
            }
          } else {
            if (mounted) {
              _showErrorMessage(
                  data['message'] ?? 'Erreur lors de la désinscription');
            }
          }
        } else {
          print('Erreur HTTP: ${response.statusCode}');
          print('Réponse: ${response.body}');
          if (mounted) {
            _showErrorMessage('Erreur de connexion');
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la désinscription: $e');
      if (mounted) {
        _showErrorMessage('Une erreur est survenue');
      }
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
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

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: _onRefresh,
                builder: _buildRefreshIndicator,
              ),
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Planning'),
                backgroundColor:
                    CupertinoColors.systemBackground.withOpacity(0.85),
                border: null,
              ),
              SliverToBoxAdapter(
                child: _buildCalendarSection(),
              ),
              SliverToBoxAdapter(
                child: _selectedDay != null
                    ? _buildSelectedDateSection()
                    : const SizedBox.shrink(),
              ),
              _buildEventsListSection(),
            ],
          ),
          if (_showFloatingButton) _buildFloatingButton(),
        ],
      ),
    );
  }

  Widget _buildRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
  ) {
    final double percentageComplete = pulledExtent / refreshTriggerPullDistance;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CupertinoActivityIndicator(
              radius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 200),
      right: 16,
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showFloatingButton ? 1.0 : 0.0,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C3E50).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              CupertinoIcons.arrow_up,
              color: CupertinoColors.white,
              size: 20,
            ),
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey6.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<dynamic>(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        eventLoader: _getEventsForDay,
        calendarStyle: _buildCalendarStyle(),
        headerStyle: _buildHeaderStyle(),
        daysOfWeekStyle: _buildDaysOfWeekStyle(),
        locale: 'fr_FR',
        availableCalendarFormats: const {
          CalendarFormat.month: 'Mois',
          CalendarFormat.week: 'Semaine',
        },
      ),
    );
  }

  Widget _buildSelectedDateSection() {
    final events = _getEventsForDay(_selectedDay!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormat('EEEE d MMMM', 'fr_FR')
                      .format(_selectedDay!)
                      .capitalize(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${events.length} séance${events.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 0.5,
              color: CupertinoColors.separator,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsListSection() {
    if (_selectedDay == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final events = _getEventsForDay(_selectedDay!);

    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: _buildEmptyState(),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= events.length) return null;
            return _buildEventCardWithAnimation(events[index], index);
          },
          childCount: events.length,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.calendar_badge_minus,
            size: 48,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune séance ce jour',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez un autre jour pour voir vos séances',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCardWithAnimation(Map<String, dynamic> event, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 200 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildEventCard(event),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final bool isInscrit = event['est_inscrit'] == 1;
    final String horseName = event['cheval_nom'] ?? '';

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showSessionDetails(event),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isInscrit
                  ? CupertinoColors.activeGreen.withOpacity(0.1)
                  : CupertinoColors.systemGrey6.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isInscrit
                ? CupertinoColors.activeGreen.withOpacity(0.2)
                : CupertinoColors.systemGrey6,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildTimeWidget(event['HD'] ?? '00:00', isInscrit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['Libcours'] ?? 'Séance',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (event['moniteur'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            event['moniteur'],
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.label.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _buildStatusBadge(isInscrit),
                ],
              ),
              if (horseName.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildHorseInfo(horseName),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    final bool isInscrit = session['est_inscrit'] == 1;
    final String horseName = session['cheval_nom'] ?? '';
    final int seanceId = int.parse(session['seance_id'].toString());

    showCupertinoModalPopup(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoActionSheet(
          title: Text(
            session['Libcours'] ?? 'Détails de la séance',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          message: Column(
            children: [
              _buildDetailRow(
                  'Date',
                  DateFormat('EEEE d MMMM yyyy', 'fr_FR')
                      .format(DateTime.parse(session['date_seance']))
                      .capitalize()),
              _buildDetailRow('Horaire', session['HD'] ?? ''),
              if (session['moniteur'] != null)
                _buildDetailRow('Moniteur', session['moniteur']),
              _buildDetailRow('Séance', 'N°${session['numero_seance']}'),
              _buildDetailRow(
                'Statut',
                isInscrit ? 'Inscrit' : 'Non inscrit',
                valueColor: isInscrit
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemGrey,
              ),
              if (isInscrit) ...[
                const SizedBox(height: 16),
                _buildDetailRow(
                  'Cheval',
                  horseName.isNotEmpty ? horseName : 'Non sélectionné',
                  valueColor: horseName.isNotEmpty
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.systemGrey,
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getAvailableHorses(seanceId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CupertinoActivityIndicator();
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('Aucun cheval disponible');
                    }

                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(8),
                      onPressed: () => _showHorseSelectionDialog(
                        context,
                        session,
                        snapshot.data!,
                      ),
                      child: Text(
                        horseName.isNotEmpty
                            ? 'Changer de cheval'
                            : 'Choisir un cheval',
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          actions: [
            if (isInscrit)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmUnsubscribe(session);
                },
                isDestructiveAction: true,
                child: const Text('Se désinscrire'),
              ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getAvailableHorses(int seanceId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/get_chevaux_disponibles.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'seance_id': seanceId.toString()}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return List<Map<String, dynamic>>.from(data['chevaux']);
        }
      }
      return [];
    } catch (e) {
      print('Erreur lors du chargement des chevaux: $e');
      return [];
    }
  }

  void _showHorseSelectionDialog(
    BuildContext context,
    Map<String, dynamic> session,
    List<Map<String, dynamic>> horses,
  ) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CupertinoActionSheet(
          title: const Text('Choisir un cheval'),
          message: const Text('Sélectionnez le cheval pour cette séance'),
          actions: horses.map((horse) {
            final bool isSelected =
                session['cheval_id']?.toString() == horse['id']?.toString();
            return CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _updateSessionHorse(session, horse);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    horse['nom'],
                    style: TextStyle(
                      color: isSelected ? CupertinoColors.activeBlue : null,
                      fontWeight: isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.checkmark_circle_fill,
                      color: CupertinoColors.activeBlue,
                      size: 18,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            isDestructiveAction: true,
            child: const Text('Annuler'),
          ),
        ),
      ),
    );
  }

  Future<void> _updateSessionHorse(
    Map<String, dynamic> session,
    Map<String, dynamic> horse,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      // Log des données initiales
      print('Début de _updateSessionHorse');
      print('Session: $session');
      print('Horse: $horse');

      if (userString != null) {
        final userData = json.decode(userString);
        final userId = userData['id'];

        // Log de la requête
        print('Envoi requête vers: $baseUrl/update_session_horse.php');
        print(
            'Données envoyées: {user_id: $userId, seance_id: ${session['seance_id']}, cheval_id: ${horse['id']}}');

        final response = await http.post(
          Uri.parse('$baseUrl/update_session_horse.php'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode({
            'user_id': userId.toString(),
            'seance_id': session['seance_id'].toString(),
            'cheval_id': horse['id'].toString(),
          }),
        );

        // Log de la réponse
        print('Status code: ${response.statusCode}');
        print('Réponse brute: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Données décodées: $data');

          if (data['success']) {
            await _loadSessions();
            if (mounted) {
              _showSuccessMessage('Cheval assigné avec succès');
            }
          } else {
            throw Exception(data['message'] ?? 'Erreur inconnue');
          }
        } else {
          throw Exception('Erreur HTTP: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Erreur dans _updateSessionHorse: $e');
      if (mounted) {
        _showErrorMessage('Erreur: $e');
      }
    }
  }

  Widget _buildTimeWidget(String time, bool isInscrit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isInscrit
            ? CupertinoColors.activeGreen.withOpacity(0.1)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isInscrit
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isInscrit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isInscrit
            ? CupertinoColors.activeGreen.withOpacity(0.1)
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isInscrit ? 'Inscrit' : 'Non inscrit',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isInscrit
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemGrey,
        ),
      ),
    );
  }

  Widget _buildHorseInfo(String horseName) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            CupertinoIcons.paw,
            size: 14,
            color: CupertinoColors.activeBlue,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          horseName,
          style: TextStyle(
            fontSize: 15,
            color: CupertinoColors.activeBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$label : ',
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label.withOpacity(0.7),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: valueColor ?? CupertinoColors.label,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmUnsubscribe(Map<String, dynamic> session) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Confirmation'),
        content: Text(
          'Êtes-vous sûr de vouloir vous désinscrire de cette séance ?\n\n'
          '${session['Libcours']}\n'
          'Le ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.parse(session['date_seance'])).capitalize()}\n'
          'à ${session['HD']}',
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _unsubscribeFromSession(session);
            },
            child: const Text('Se désinscrire'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _selectCalendarView() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Vue du calendrier'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _calendarFormat = CalendarFormat.month);
              Navigator.pop(context);
            },
            child: const Text('Mois'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _calendarFormat = CalendarFormat.week);
              Navigator.pop(context);
            },
            child: const Text('Semaine'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: true,
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  CalendarStyle _buildCalendarStyle() {
    return CalendarStyle(
      isTodayHighlighted: true,
      selectedDecoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: CupertinoColors.activeBlue.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.activeBlue),
      ),
      markerDecoration: BoxDecoration(
        color: CupertinoColors.activeBlue,
        shape: BoxShape.circle,
      ),
      markersMaxCount: 4,
      markerSize: 6,
      markerMargin: const EdgeInsets.symmetric(horizontal: 0.3),
      outsideDaysVisible: false,
      weekendTextStyle:
          TextStyle(color: CupertinoColors.systemRed.withOpacity(0.8)),
    );
  }

  HeaderStyle _buildHeaderStyle() {
    return HeaderStyle(
      titleCentered: true,
      formatButtonVisible: false,
      titleTextStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      leftChevronIcon: const Icon(
        CupertinoIcons.chevron_left,
        size: 20,
        color: CupertinoColors.activeBlue,
      ),
      rightChevronIcon: const Icon(
        CupertinoIcons.chevron_right,
        size: 20,
        color: CupertinoColors.activeBlue,
      ),
    );
  }

  DaysOfWeekStyle _buildDaysOfWeekStyle() {
    return const DaysOfWeekStyle(
      weekdayStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.label,
      ),
      weekendStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: CupertinoColors.systemRed,
      ),
    );
  }
}

// Extension pour capitaliser la première lettre
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Fonctions utilitaires pour l'adaptabilité
double _getAdaptiveFontSize(BuildContext context, double min, double max) {
  final width = MediaQuery.of(context).size.width;
  return width < 375 ? min : max;
}

double _getAdaptiveSpacing(BuildContext context, double min, double max) {
  final width = MediaQuery.of(context).size.width;
  return width < 375 ? min : max;
}

double _getAdaptiveHeight(BuildContext context, double min, double max) {
  final width = MediaQuery.of(context).size.width;
  return width < 375 ? min : max;
}

double _getAdaptiveIconSize(BuildContext context, double min, double max) {
  final width = MediaQuery.of(context).size.width;
  return width < 375 ? min : max;
}
