import 'package:flutter/material.dart';
import 'DriverAuthPage.dart';
import 'student_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  void navigateToDriverAuth(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DriverAuthPage()),
    );
  }

  void navigateToStudentPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StudentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bronco Shuttle App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => navigateToDriverAuth(context),
              child: const Text('Driver Login'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => navigateToStudentPage(context),
              child: const Text('Shuttle Status'),
            ),
          ],
        ),
      ),
    );
  }
}
