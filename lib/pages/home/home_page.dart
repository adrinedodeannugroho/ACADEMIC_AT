import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: const Center(
        child: Text(
          "Selamat Datang di Aplikasi",
          style: TextStyle(
            fontSize: 24,
          ),
        ),
      ),
    );
  }
}