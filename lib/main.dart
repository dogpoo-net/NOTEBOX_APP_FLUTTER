import 'package:flutter/material.dart';

import 'features/inbox/inbox_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NOTEBOX',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF7F5EF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF426653),
        surface: const Color(0xFFF7F5EF),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.white,
      ),
    ),
    home: const InboxPage(),
  );
}
