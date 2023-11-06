import 'package:flutter/material.dart';
import '../main.dart';
import 'register_page.dart';
import '../pages/driver_page.dart';
import '../pages/mechanic_page.dart';
import '../service/mongo_service.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  // final List<String> selectedVehicleTypes;

  // LoginPage({required this.selectedVehicleTypes});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void showInvalidCredentialsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(
          'Invalid credentials. Please check your email and password.',
        ),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void login() async {
    final email = emailController.text;
    final password = passwordController.text;

    

    setState(() {
      isLoading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    await loginUser(email, password).then((user) {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context);
      if (user != null) {
        // Get the LoginSession provider and set the user ID
        final loginSession = Provider.of<LoginSession>(context, listen: false);
        loginSession
            .setUserId(user['_id']);
            //  loginSession.setFirstName(user['firstName']); // Assuming the user ID field is '_id'
        print(user['_id']);

        if (user['role'] == 'Mechanic') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MechanicPage(
                        sessionId: user['_id'],
                        selectedVehicleTypes: [
                          'Automotive',
                          'Motorcycle',
                          'Bicycle'
                        ])),
          );
        } else if (user['role'] == 'Driver') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => DriverPage(sessionId: user['_id'])),
          );
        }
        // Login successful, navigate to the home page or perform required action
      } else {
        showInvalidCredentialsDialog();
      }
    }).catchError((error) {
      setState(() {
        isLoading = false;
      });
      Navigator.pop(context); // Close the loading overlay
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Login failed. Please try again.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    });
  }

  void navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 4.0,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.0),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 32.0),
                  ElevatedButton(
                    child: Text('Login'),
                    onPressed: login,
                  ),
                  SizedBox(height: 16.0),
                  TextButton(
                    child: Text('Not yet registered? Click here to register.'),
                    onPressed: navigateToRegister,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}




// import 'package:flutter/material.dart';
// import '../main.dart';
// import 'register_page.dart';
// import '../pages/driver_page.dart';
// import '../pages/mechanic_page.dart';
// import '../service/mongo_service.dart';
// import 'package:provider/provider.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   bool isLoading = false;

//   void showInvalidCredentialsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Error'),
//         content: Text(
//           'Invalid credentials. Please check your email and password.',
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: Text('OK'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }

//   void login() async {
//     final email = emailController.text;
//     final password = passwordController.text;

//     setState(() {
//       isLoading = true;
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     await loginUser(email, password).then((user) {
//       setState(() {
//         isLoading = false;
//       });
//       Navigator.pop(context);
//       if (user != null) {
//         // Get the LoginSession provider and set the user ID
//         final loginSession = Provider.of<LoginSession>(context, listen: false);
//         loginSession
//             .setUserId(user['_id']); // Assuming the user ID field is '_id'
//         print(user['_id']);

//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(builder: (context) => HomePage()),
//         // );

//         if (user['role'] == 'Mechanic') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => MechanicPage(sessionId: user['_id'])),
//           );
//         } else if (user['role'] == 'Driver') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => DriverPage(sessionId: user['_id'])),
//           );
//         }
//         // Login successful, navigate to the home page or perform required action
//       } else {
//         showInvalidCredentialsDialog();
//         // showDialog(builder: (BuildContext context) {  }, context: null
//         //     // ...
//         //     );
//       } // Close the loading overlay
//       // Login successful, navigate to the home page or perform required action
//     }).catchError((error) {
//       setState(() {
//         isLoading = false;
//       });
//       Navigator.pop(context); // Close the loading overlay
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Error'),
//           content: Text('Login failed. Please try again.'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   void navigateToRegister() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => RegisterPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Login',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20.0,
//             fontWeight: FontWeight.bold,
//             fontFamily: 'Roboto', // Replace with your desired font
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [Color(0xFFEE4949), Color(0xFFFC8585)],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(16.0),
//             child: Card(
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10.0),
//               ),
//               elevation: 4.0,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     TextField(
//                       controller: emailController,
//                       decoration: InputDecoration(labelText: 'Email'),
//                     ),
//                     SizedBox(height: 16.0),
//                     TextField(
//                       controller: passwordController,
//                       decoration: InputDecoration(labelText: 'Password'),
//                       obscureText: true,
//                     ),
//                     SizedBox(height: 16.0),
//                     ElevatedButton(
//                       child: Text('Login'),
//                       onPressed: login,
//                     ),
//                     SizedBox(height: 16.0),
//                     Text(
//                       'Not yet registered? Click below to register:',
//                       style: TextStyle(fontSize: 16.0),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 8.0),
//                     TextButton(
//                       child: Text('Register'),
//                       onPressed: navigateToRegister,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }





// import 'package:flutter/material.dart';
// import '../main.dart';
// import 'register_page.dart';
// import '../pages/driver_page.dart';
// import '../pages/mechanic_page.dart';
// import '../service/mongo_service.dart';
// import 'package:provider/provider.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   TextEditingController emailController = TextEditingController();
//   TextEditingController passwordController = TextEditingController();
//   bool isLoading = false;

//   void showInvalidCredentialsDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Error'),
//         content: Text(
//           'Invalid credentials. Please check your email and password.',
//         ),
//         actions: <Widget>[
//           TextButton(
//             child: Text('OK'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }

//   void login() async {
//     final email = emailController.text;
//     final password = passwordController.text;

//     setState(() {
//       isLoading = true;
//     });

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return Center(
//           child: CircularProgressIndicator(),
//         );
//       },
//     );

//     await loginUser(email, password).then((user) {
//       setState(() {
//         isLoading = false;
//       });
//       Navigator.pop(context);
//       if (user != null) {
//         // Get the LoginSession provider and set the user ID
//         final loginSession = Provider.of<LoginSession>(context, listen: false);
//         loginSession
//             .setUserId(user['_id']); // Assuming the user ID field is '_id'
//         print(user['_id']);

//         // Navigator.pushReplacement(
//         //   context,
//         //   MaterialPageRoute(builder: (context) => HomePage()),
//         // );

//         if (user['role'] == 'Mechanic') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => MechanicPage(sessionId: user['_id'])),
//           );
//         } else if (user['role'] == 'Driver') {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//                 builder: (context) => DriverPage(sessionId: user['_id'])),
//           );
//         }
//         // Login successful, navigate to the home page or perform required action
//       } else {
//         showInvalidCredentialsDialog();
//         // showDialog(builder: (BuildContext context) {  }, context: null
//         //     // ...
//         //     );
//       } // Close the loading overlay
//       // Login successful, navigate to the home page or perform required action
//     }).catchError((error) {
//       setState(() {
//         isLoading = false;
//       });
//       Navigator.pop(context); // Close the loading overlay
//       showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//           title: Text('Error'),
//           content: Text('Login failed. Please try again.'),
//           actions: <Widget>[
//             TextButton(
//               child: Text('OK'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//           ],
//         ),
//       );
//     });
//   }

//   void navigateToRegister() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => RegisterPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Center(
//             child: Text('Raamb App', style: TextStyle(color: Colors.white))),
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               TextField(
//                 controller: emailController,
//                 decoration: InputDecoration(labelText: 'Email'),
//               ),
//               SizedBox(height: 16.0),
//               TextField(
//                 controller: passwordController,
//                 decoration: InputDecoration(labelText: 'Password'),
//                 obscureText: true,
//               ),
//               SizedBox(height: 16.0),
//               ElevatedButton(
//                 child: Text('Login'),
//                 onPressed: login,
//               ),
//               SizedBox(height: 16.0),
//               Text(
//                 'Not yet registered? Click below to register:',
//                 style: TextStyle(fontSize: 16.0),
//                 textAlign: TextAlign.center,
//               ),
//               SizedBox(height: 8.0),
//               TextButton(
//                 child: Text('Register'),
//                 onPressed: navigateToRegister,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
