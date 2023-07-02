import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:palaction/firebase_options.dart';
import 'package:palaction/screens/auth/register_screen.dart';
import 'package:palaction/screens/mapscreens/map_home.dart';
import 'package:provider/provider.dart';
import 'package:palaction/shared/auth_service.dart';
import 'package:palaction/shared/widgets/drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Auth Example',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        initialRoute: '/map_home',
        routes: {
          '/map_home': (context) => MapHome(),
          '/register': (context) => RegisterScreen(),
        },
      ),
    );
  }
}
