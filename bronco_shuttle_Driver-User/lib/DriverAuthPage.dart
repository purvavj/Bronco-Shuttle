import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'DriverRouteSelectionPage.dart';

class DriverAuthPage extends StatefulWidget {
  const DriverAuthPage({Key? key}) : super(key: key);

  @override
  State<DriverAuthPage> createState() => _DriverAuthPageState();
}

class _DriverAuthPageState extends State<DriverAuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _login() async {
    try {
      // Sign in with email and password.
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Force token refresh and get the ID token result, which contains custom claims.
      final idTokenResult = await userCredential.user!.getIdTokenResult(true);

      // Check if the custom claim 'driver' is set to true.
      if (idTokenResult.claims != null &&
          idTokenResult.claims!['driver'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverRouteSelectionPage(),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'You are not authorized as a driver.';
        });
        await _auth.signOut();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Login'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login as Driver'),
            ),
          ],
        ),
      ),
    );
  }
}
