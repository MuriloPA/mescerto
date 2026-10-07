import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'config.dart';
import 'finance.dart';
import 'screens/auth.dart';
import 'screens/entry.dart';
import 'screens/extras.dart';
import 'screens/goals.dart';
import 'screens/shell.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  // A URL e a chave PÚBLICA ficam em config.dart. Nunca use a service_role.
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(ChangeNotifierProvider(
    create: (_) => FinanceProvider(),
    child: const MesCertoApp(),
  ));
}

/// Avisa o roteador quando o login muda (entrou/saiu), para ele redirecionar.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh() {
    Supabase.instance.client.auth.onAuthStateChange
        .listen((_) => notifyListeners());
  }
}

final _authRefresh = _AuthRefresh();

/// Sem login só as telas públicas; com login, pula direto para o app.
String? _redirect(BuildContext context, GoRouterState state) {
  final loggedIn = Supabase.instance.client.auth.currentSession != null;
  final loc = state.matchedLocation;
  final isPublic = loc == '/' || loc == '/login' || loc == '/register';
  if (!loggedIn && !isPublic) return '/';
  if (loggedIn && isPublic) return '/home';
  return null;
}

final _router = GoRouter(
  refreshListenable: _authRefresh,
  redirect: _redirect,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (_, __) => const MainShell()),
    GoRoute(
        path: '/new-entry',
        builder: (_, s) => NewEntryScreen(id: s.uri.queryParameters['id'])),
    GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
    GoRoute(
        path: '/subscriptions',
        builder: (_, __) => const SubscriptionsScreen()),
    GoRoute(path: '/alerts', builder: (_, __) => const AlertsScreen()),
    GoRoute(
      path: '/new-goal',
      pageBuilder: (_, __) =>
          const MaterialPage(fullscreenDialog: true, child: NewGoalScreen()),
    ),
  ],
);

class MesCertoApp extends StatelessWidget {
  const MesCertoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final f = context.watch<FinanceProvider>();
    final dark = f.isDark;
    return MaterialApp.router(
      title: 'MêsCerto',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      scaffoldMessengerKey: messengerKey,
      // Barra fininha no topo enquanto os dados chegam da internet.
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          if (f.loading)
            const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3)),
        ],
      ),
      theme: ThemeData(
        useMaterial3: true,
        brightness: dark ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: f.colors.background,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.light.primary,
            brightness: dark ? Brightness.dark : Brightness.light),
      ),
    );
  }
}
