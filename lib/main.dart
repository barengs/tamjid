import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/api/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/student_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  // Inisialisasi Dio Client
  DioClient().init();

  final authProvider = AuthProvider();
  await authProvider.bootstrap();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tamjid Wali',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      home: const _Root(),
      routes: {
        '/login': (context) => LoginScreen(
              authProvider: context.read<AuthProvider>(),
              onLoginSuccess: () {},
            ),
        '/register': (context) => RegisterScreen(
              authProvider: context.read<AuthProvider>(),
              onRegisterSuccess: () {},
            ),
      },
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!_initialized) {
      return const SplashScreen();
    }

    if (authProvider.isAuthenticated) {
      return HomeScreen(
        authProvider: authProvider,
        onLogout: () {
          context.read<StudentProvider>().reset();
          authProvider.logout();
        },
      );
    }

    return LoginScreen(
      authProvider: authProvider,
      onLoginSuccess: () {},
    );
  }
}
