import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminCoursesPage extends StatefulWidget {
  const AdminCoursesPage({Key? key}) : super(key: key);

  @override
  State<AdminCoursesPage> createState() => _AdminCoursesPageState();
}

class _AdminCoursesPageState extends State<AdminCoursesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _libcoursController = TextEditingController();
  TimeOfDay _heureDebut = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _heureFin = const TimeOfDay(hour: 9, minute: 0);
  String _jourSelectionne = 'Lundi';
  bool _isLoading = false;

  final List<String> _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche'
  ];

  final String baseUrl = 'http://172.20.10.14:8888/api/admin';

  void _showTimePicker(bool isStartTime) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 280,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 40,
                color: CupertinoColors.systemGrey6,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: DateTime(
                    2022,
                    1,
                    1,
                    isStartTime ? _heureDebut.hour : _heureFin.hour,
                    isStartTime ? _heureDebut.minute : _heureFin.minute,
                  ),
                  onDateTimeChanged: (DateTime newDateTime) {
                    setState(() {
                      if (isStartTime) {
                        _heureDebut = TimeOfDay(
                          hour: newDateTime.hour,
                          minute: newDateTime.minute,
                        );
                      } else {
                        _heureFin = TimeOfDay(
                          hour: newDateTime.hour,
                          minute: newDateTime.minute,
                        );
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _createCourse() async {
    if (_libcoursController.text.trim().isEmpty) {
      _showErrorDialog('Veuillez entrer un nom de cours');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'Libcours': _libcoursController.text.trim(),
        'jour': _jourSelectionne,
        'HD': _formatTimeOfDay(_heureDebut),
        'HF': _formatTimeOfDay(_heureFin),
      };

      final response = await http.post(
        Uri.parse('$baseUrl/create_course.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      final responseData = json.decode(response.body);

      if (responseData['success']) {
        _showSuccessDialog();
        _resetForm();
      } else {
        _showErrorDialog(
            responseData['message'] ?? 'Erreur lors de la création');
      }
    } catch (e) {
      _showErrorDialog('Erreur lors de la création du cours');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: const Text('Le cours a été créé avec succès !'),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
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

  void _resetForm() {
    _libcoursController.clear();
    setState(() {
      _heureDebut = const TimeOfDay(hour: 8, minute: 0);
      _heureFin = const TimeOfDay(hour: 9, minute: 0);
      _jourSelectionne = 'Lundi';
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Administration',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
        trailing: _isLoading
            ? const CupertinoActivityIndicator()
            : GestureDetector(
                onTap: _createCourse,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Créer',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          CupertinoIcons.book_circle_fill,
                          size: 40,
                          color: CupertinoColors.activeBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nouveau cours',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Créez un nouveau cours pour les cavaliers',
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.secondaryLabel,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.systemGrey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildFormSection(
                        title: 'INFORMATIONS',
                        icon: CupertinoIcons.doc_text_fill,
                        children: [
                          _buildTextField(
                            controller: _libcoursController,
                            placeholder: 'Nom du cours',
                            prefix: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color:
                                    CupertinoColors.activeBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.book_fill,
                                size: 18,
                                color: CupertinoColors.activeBlue,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDaySelector(),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1),
                      ),
                      _buildFormSection(
                        title: 'HORAIRES',
                        icon: CupertinoIcons.clock_fill,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Début',
                                  time: _heureDebut,
                                  onTap: () => _showTimePicker(true),
                                  icon: CupertinoIcons.time,
                                  gradient: const [
                                    Color(0xFF4CAF50),
                                    Color(0xFF2E7D32)
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeSelector(
                                  label: 'Fin',
                                  time: _heureFin,
                                  onTap: () => _showTimePicker(false),
                                  icon: CupertinoIcons.time_solid,
                                  gradient: const [
                                    Color(0xFF5C6BC0),
                                    Color(0xFF3949AB)
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _createCourse,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.check_mark_circled_solid,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Créer le cours',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({
    required String title,
    required List<Widget> children,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  size: 14,
                  color: CupertinoColors.activeBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    Widget? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (prefix != null) ...[
            prefix,
            const SizedBox(width: 8),
          ],
          Expanded(
            child: CupertinoTextField.borderless(
              controller: controller,
              placeholder: placeholder,
              padding: const EdgeInsets.symmetric(vertical: 12),
              style: TextStyle(color: CupertinoColors.label),
              placeholderStyle:
                  TextStyle(color: CupertinoColors.secondaryLabel),
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    // Vous pouvez ajouter un état d'erreur si nécessaire
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return GestureDetector(
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => Container(
            height: 250,
            color: CupertinoColors.systemBackground,
            child: Column(
              children: [
                Container(
                  height: 50,
                  color: CupertinoColors.systemGrey6,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ),
                Expanded(
                  child: CupertinoPicker(
                    backgroundColor: CupertinoColors.systemBackground,
                    itemExtent: 40,
                    children: _jours
                        .map((jour) => Center(child: Text(jour)))
                        .toList(),
                    onSelectedItemChanged: (index) {
                      setState(() => _jourSelectionne = _jours[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              CupertinoIcons.calendar,
              size: 20,
              color: CupertinoColors.activeBlue,
            ),
            const SizedBox(width: 8),
            Text(
              _jourSelectionne,
              style: TextStyle(color: CupertinoColors.label),
            ),
            const Spacer(),
            Icon(
              CupertinoIcons.chevron_down,
              size: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              gradient[0].withOpacity(0.1),
              gradient[1].withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: gradient[0].withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: gradient[0],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatTimeOfDay(time),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _libcoursController.dispose();
    super.dispose();
  }
}
