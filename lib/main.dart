import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'l10n.dart';
import 'server_config.dart';
import 'pages/home_page.dart';
import 'pages/chat_page.dart';
import 'pages/discover_page.dart';
import 'pages/messages_page.dart';
import 'pages/profile_page.dart';
import 'pages/character_detail_page.dart';
import 'pages/create_character_page.dart';
import 'pages/create_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/privacy_page.dart';
import 'pages/server_select_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await ApiService().init();
  await ServerManager().init();
  await AppLocale.instance.load();
  // 已配置服务器时，每次启动自动从服务器拉取 api.json（失败时回退缓存）
  if (ServerManager().isConfigured) {
    try {
      await ApiService().fetchApiConfig();
    } catch (_) {}
  }
  runApp(const YueWuApp());
}

class YueWuApp extends StatefulWidget {
  const YueWuApp({super.key});

  @override
  State<YueWuApp> createState() => _YueWuAppState();
}

class _YueWuAppState extends State<YueWuApp> {
  @override
  void initState() {
    super.initState();
    AppLocale.instance.langNotifier.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    AppLocale.instance.langNotifier.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFFFFB6C1);
    const secondary = Color(0xFFFFC0CB);
    const background = Color(0xFFFFF0F5);

    return MaterialApp(
      title: '月悟',
      debugShowCheckedModeBanner: false,
      navigatorKey: ApiService.navigatorKey,
      navigatorObservers: [routeObserver],
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: primary,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: Colors.white,
          surface: background,
          onSurface: Color(0xFF4A4A4A),
          error: Color(0xFFD32F2F),
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: background,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: background,
          indicatorColor: primary.withValues(alpha: 0.2),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          ),
        ),
      ),
      initialRoute: !ServerManager().isConfigured
          ? '/server_select'
          : ApiService().isLoggedIn
              ? '/main'
              : '/login',
      routes: {
        '/server_select': (_) => const ServerSelectPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
        '/main': (_) => const MainPage(),
        '/home': (_) => const HomePage(),
        '/discover': (_) => const DiscoverPage(),
        '/messages': (_) => const MessagesPage(),
        '/profile': (_) => const ProfilePage(),
        '/create_character': (_) => const CreateCharacterPage(),
        '/privacy': (_) => const PrivacyPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ChatPage(
                characterId: '${args['characterId']}',
                storyId: args['storyId']?.toString(),
                characterName: args['characterName'] ?? '',
              ),
            );
          case '/character_detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => CharacterDetailPage(characterId: '${args['characterId']}'),
            );
        }
        return null;
      },
    );
  }
}

class _AiBadgeIcon extends StatelessWidget {
  const _AiBadgeIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFB6C1), Color(0xFFFFC0CB)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB6C1).withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.add, size: 28, color: Colors.white),
        ),
        Positioned(
          right: -4,
          top: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: const Text(
              'AI',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const DiscoverPage(),
    const CreatePage(),
    const MessagesPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 2) {
            _showCreateSheet();
            return;
          }
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: '伙伴',
          ),
          NavigationDestination(
            icon: _AiBadgeIcon(),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: '消息',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }

  void _showCreateSheet() {
    final options = [
      _CreateOption(Icons.auto_awesome, const Color(0xFFFFB6C1), 'AI创作角色', '用AI生成你的专属伙伴', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePage(initialIndex: 1)));
      }),
      _CreateOption(Icons.edit, const Color(0xFF90CAF9), '手动创建角色', '从零开始定制你的伙伴', () {
        Navigator.pop(context);
        Navigator.pushNamed(context, '/create_character');
      }),
      _CreateOption(Icons.image, const Color(0xFF80DEEA), '捏形象', '生成角色立绘图片', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePage(initialIndex: 0)));
      }),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFF0F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('创作中心',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            ...options.map((o) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: o.color.withValues(alpha: 0.2),
                    child: Icon(o.icon, color: o.color),
                  ),
                  title: Text(o.title),
                  subtitle: Text(o.subtitle),
                  onTap: o.onTap,
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _CreateOption {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _CreateOption(this.icon, this.color, this.title, this.subtitle, this.onTap);
}
