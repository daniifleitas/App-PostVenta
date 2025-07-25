import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auditoria/auditoria_screen.dart';
import 'screens/puesta_en_marcha/puesta_marcha_screen.dart';
import 'screens/garantia/garantia_screen.dart';

void main() => runApp(const HitachiApp());

class HitachiApp extends StatelessWidget {
  const HitachiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE11931)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),  // ✅ Definido correctamente
      routes: {                 // ✅ Definido correctamente
        '/auditoria': (context) => const AuditoriaScreen(),
        '/puesta_en_marcha': (context) => const PuestaMarchaScreen(),
        '/garantia': (context) => const GarantiaScreen(),
      },
    ); // <- ¡No olvides este punto y coma!
  }
}