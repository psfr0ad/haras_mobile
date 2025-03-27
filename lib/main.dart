import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/courses_page.dart';
import 'pages/settings_page.dart';
import 'pages/admin_courses_page.dart';
import 'pages/moniteur_courses_page.dart';
import 'pages/calendar_page.dart';
import 'pages/courses_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import '/services/api_service.dart';
import 'widgets/auth_wrapper.dart';
import 'services/auth_navigator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: AuthNavigator.navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Haras Mobile',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr', 'FR'),
      ],
      theme: const CupertinoThemeData(
        primaryColor: Color(0xFF2C3E50),
        brightness: Brightness.light,
        scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
      ),
      home: FutureBuilder<String?>(
        future: _checkInitialRoute(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CupertinoActivityIndicator(),
            );
          }
          return snapshot.data != null
              ? const MainNavigationPage()
              : const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigationPage(),
      },
    );
  }

  Future<String?> _checkInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final user = prefs.getString('user');

      if (token != null && user != null) {
        return token;
      }
      return null;
    } catch (e) {
      print('Erreur lors de la vérification des données stockées: $e');
      return null;
    }
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({Key? key}) : super(key: key);

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;
  List<Widget> _pages = const [
    HomePage(),
    CalendarPage(),
    CoursesPage(),
    ProfilePage(),
    SettingsPage(),
  ];

  List<BottomNavigationBarItem> _navigationItems = const [
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.home),
      label: 'Accueil',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.calendar),
      label: 'Calendrier',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.book),
      label: 'Cours',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.person),
      label: 'Profil',
    ),
    BottomNavigationBarItem(
      icon: Icon(CupertinoIcons.settings),
      label: 'Paramètres',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');

      if (userString != null) {
        final userData = json.decode(userString);
        print('User Data: $userData');

        final userRole = userData['id_role']?.toString() ?? '2';
        print('User Role: $userRole');

        if (userRole == '1') {
          if (mounted) {
            setState(() {
              _pages = const [
                HomePage(),
                CalendarPage(),
                CoursesPage(),
                ProfilePage(),
                SettingsPage(),
                AdminCoursesPage(),
              ];

              _navigationItems = const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.home),
                  label: 'Accueil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.calendar),
                  label: 'Calendrier',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.book),
                  label: 'Cours',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: 'Profil',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.settings),
                  label: 'Paramètres',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.shield),
                  label: 'Admin',
                ),
              ];
            });
          }
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification du rôle: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: _navigationItems,
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        activeColor: const Color(0xFF2C3E50),
        inactiveColor: const Color(0xFF6C757D),
      ),
      tabBuilder: (BuildContext context, int index) {
        return CupertinoTabView(
          builder: (context) {
            return CupertinoPageScaffold(
              child: _pages[index],
            );
          },
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatefulWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  State<AuthenticationWrapper> createState() => _AuthenticationWrapperState();
}

class _AuthenticationWrapperState extends State<AuthenticationWrapper> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    print('Token au démarrage: $token');

    if (token == null || token.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoginPage();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool isAdmin = false;
  bool isMoniteur = false;
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      print('1. Raw User String: $userString');

      if (userString != null) {
        final userDataTemp = json.decode(userString);
        print('2. Parsed User Data: $userDataTemp');
        print('3. Type of id_role: ${userDataTemp['id_role'].runtimeType}');
        print('4. Value of id_role: ${userDataTemp['id_role']}');

        setState(() {
          userData = userDataTemp;
          final roleValue = userDataTemp['id_role'];
          print('5. Role Value: $roleValue');

          isAdmin =
              roleValue == 1 || roleValue == '1' || roleValue.toString() == '1';
          isMoniteur =
              roleValue == 3 || roleValue == '3' || roleValue.toString() == '3';

          print('6. Final isAdmin value: $isAdmin');
          print('7. Final isMoniteur value: $isMoniteur');
        });
      } else {
        print('No user data found in SharedPreferences');
      }
    } catch (e) {
      print('Error in _checkUserRole: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  List<Widget> get _pages => [
        const HomePage(),
        const CoursesPage(),
        const CalendarPage(),
        const ProfilePage(),
        const SettingsPage(),
        if (isAdmin) const AdminCoursesPage(),
        if (isMoniteur) const MoniteurCoursesPage(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CupertinoTabScaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        tabBar: CupertinoTabBar(
          backgroundColor: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFE0E3E7),
              width: 0.5,
            ),
          ),
          items: [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.list_bullet),
              label: 'Cours',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.calendar),
              label: 'Calendrier',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.person),
              label: 'Profil',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.settings),
              label: 'Paramètres',
            ),
            if (isAdmin)
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.shield),
                label: 'Admin',
              ),
            if (isMoniteur)
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.person_badge_plus),
                label: 'Moniteur',
              ),
          ],
          activeColor: const Color(0xFF2C3E50),
          inactiveColor: const Color(0xFF6C757D),
        ),
        tabBuilder: (BuildContext context, int index) {
          return CupertinoTabView(
            builder: (context) {
              return Container(
                color: const Color(0xFFF8F9FA),
                child: SafeArea(
                  child: _pages[index],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminFloatingButton extends StatelessWidget {
  const AdminFloatingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2C3E50).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AdminCoursesPage(),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(
                CupertinoIcons.shield,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
