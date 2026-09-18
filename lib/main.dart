import 'package:flutter/material.dart';
import 'api.dart';
import 'pages/home_page.dart';
import 'pages/partner_page.dart';
import 'pages/create_page.dart';
import 'pages/messages_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const YueWuApp());
}

class YueWuApp extends StatelessWidget {
  const YueWuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '月悟',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF69B4),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final t = await Api.token;
    setState(() {
      _loggedIn = t != null && t.isNotEmpty;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_loggedIn) {
      return LoginPage(onLogin: () => setState(() => _loggedIn = true));
    }
    return const MainShell();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final _pages = [
    const HomePage(),
    const PartnerPage(),
    const CreatePage(),
    const MessagesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '主页'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), selectedIcon: Icon(Icons.favorite), label: '伙伴'),
          NavigationDestination(
            icon: Badge(label: Text('AI'), child: Icon(Icons.add_circle_outline, size: 32)),
            selectedIcon: Badge(label: Text('AI'), child: Icon(Icons.add_circle, size: 32)),
            label: '创作',
          ),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: '消息'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}
