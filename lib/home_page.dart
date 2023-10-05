import 'package:flutter/material.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import './auth/login_page.dart';
import './service/mongo_service.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final loginSession = Provider.of<LoginSession>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: Center(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: getUserData(loginSession.getUserId()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (snapshot.hasData) {
              final userData = snapshot.data!;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      'Welcome ${userData['firstName']} ${userData['lastName']}!'),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    child: Text('Logouts'),
                    onPressed: () {
                      loginSession.clearUserId();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                  ),
                ],
              );
            } else {
              return Text('No user data found.');
            }
          },
        ),
      ),
    );
  }
}
