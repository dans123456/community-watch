import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'widgets/motion.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: AppConfig.supabaseAnonKey,
  );
  runApp(const CommunityWatchApp());
}

class CommunityWatchApp extends StatelessWidget {
  const CommunityWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Watch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF123B5D)),
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const _FadeSlidePageTransitionsBuilder(),
          },
        ),
      ),
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          return AnimatedSwitcher(
            duration: Motion.page,
            switchInCurve: Motion.curve,
            switchOutCurve: Motion.curve,
            transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
            child: session == null
                ? const LoginScreen(key: ValueKey('login'))
                : const HomeScreen(key: ValueKey('home')),
          );
        },
      ),
    );
  }
}

/// Applies the app's gentle fade+slide transition to routes created with the
/// standard MaterialPageRoute (e.g. from platform back-gestures), so motion
/// stays consistent even outside the explicit pushAnimated() helper.
class _FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(parent: animation, curve: Motion.curve, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}
