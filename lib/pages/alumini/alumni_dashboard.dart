import 'package:flutter/material.dart';

class AlumniDashboardPage extends StatelessWidget {
  const AlumniDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Alumni Dashboard")),
      body: const Center(child: Text("Welcome, Alumni!")),
    );
  }
}
