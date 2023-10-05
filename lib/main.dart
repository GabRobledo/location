import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home_page.dart';
import './auth/login_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class LoginSession with ChangeNotifier {
  String? _userId;

  String? getUserId() {
    return _userId;
  }

  void setUserId(String? userId) {
    _userId = userId;
    notifyListeners();
  }

  void clearUserId() {
    _userId = null;
    notifyListeners();
  }
}

void main() {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  runApp(
    ChangeNotifierProvider(
      create: (_) => LoginSession(),
      child: MyApp(),
    ),
  );
  FlutterNativeSplash.remove();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<LoginSession>(
      builder: (context, loginSession, _) {
        return MaterialApp(
          title: 'Location App',
          theme: ThemeData(
              primarySwatch: MaterialColor(
            0xFFEE4949, // Replace with your desired hexadecimal color value
            <int, Color>{
              50: Color(0xFFFFE7E7),
              100: Color(0xFFFFC5C5),
              200: Color(0xFFFF9C9C),
              300: Color(0xFFFF7373),
              400: Color(0xFFFF5353),
              500: Color(0xFFEE4949), // Set the primary color to #EE4949
              600: Color(0xFFEE4242),
              700: Color(0xFFEE3B3B),
              800: Color(0xFFEE3333),
              900: Color(0xFFEE2929),
            },
          )),
          initialRoute: '/',
          routes: {
            '/': (context) {
              // Check if there is an active login session
              // if (loginSession.getUserId() != null) {
              //   // Redirect to the home page
              //   return HomePage();
              // } else {
              //   // Redirect to the login page
              //   return LoginPage();
              // }
              return LoginPage();
            },
            '/home': (context) => HomePage(),
          },
        );
      },
    );
  }
}
