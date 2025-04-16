import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home.dart';
import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/signup_page.dart';
import 'screens/chat_front_page.dart';
import 'screens/chat_page.dart';
import 'screens/generate_report.dart';
import 'package:firebase_database/firebase_database.dart';
import 'screens/global_anomaly_listener.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform.copyWith(
      databaseURL: 'https://healthcare-578bf-default-rtdb.firebaseio.com/',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Smart Healthcare',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/home',
      builder: (context, child) {
        final currentRoute = ModalRoute.of(context)?.settings.name ?? '';
        return GlobalAnomalyListener(
          child: child ?? const SizedBox(),
          currentRoute: currentRoute,
        );
      },
      routes: {
        '/home': (context) => const WelcomePage(),
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home_page': (context) => const HomePage(),
        '/chat_front_page': (context) => const ChatFrontPage(),
        '/report': (context) => const GenerateReportPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/chat_page') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ChatPage(
              chatId: args['chatId'],
              receiverName: args['receiverName'],
              receiverId: args['receiverId'],
            ),
          );
        }
        return null;
      },
    );
  }
}
