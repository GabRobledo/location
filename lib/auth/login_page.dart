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
  final _formKey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

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
  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty || !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      decoration: InputDecoration(
        labelText: 'Password',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _passwordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
        ),
      ),
      obscureText: !_passwordVisible,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your password';
        }
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
  return ElevatedButton(
    child: Text('Login'),
    onPressed: () {
      // Add a null check before calling validate
      if (_formKey.currentState?.validate() ?? false) {
        login();
      }
    },
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
  );
}


  Widget _buildRegisterButton() {
    return TextButton(
      child: Text('Not yet registered? Click here to register.'),
      onPressed: navigateToRegister,
    );
  }
  Widget _buildLogo() {
    
    return Center(
      child: Image.asset(
        'assets/temp2.png',
        width: 100, 
      ),
    );
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 5.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // _buildLogo(),
                      // SizedBox(height: 40), // Provide some spacing after the logo
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.headline4,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      _buildEmailField(),
                      SizedBox(height: 16),
                      _buildPasswordField(),
                      SizedBox(height: 24),
                      _buildLoginButton(),
                      SizedBox(height: 16),
                      _buildRegisterButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
  

  

