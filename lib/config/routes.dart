import 'package:flutter/material.dart';
import '../pages/login/login_page.dart';
import '../pages/home/home_page.dart';

Map<String, WidgetBuilder> routes = {
  '/': (context) => const LoginPage(),
  '/home': (context) => const HomePage(),
};