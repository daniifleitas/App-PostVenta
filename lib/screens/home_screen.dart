import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE00420),
        title: SvgPicture.asset(
          'assets/logo.png',
          height: 32,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn), // Sin errores
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TEXTO DE BIENVENIDA (SOLO ESTO ES NUEVO)
            const Text(
              '¡BIENVENIDOS AL ÁREA DE POST-VENTA!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE00420), // Rojo Hitachi
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30), // Espacio adicional

            // Botones originales (NO TOCAR)
            _buildHitachiButton(
              context: context,
              text: "AUDITORÍA",
              icon: Icons.assessment_outlined,
              onPressed: () => Navigator.pushNamed(context, '/auditoria'),
            ),
            const SizedBox(height: 20),
            _buildHitachiButton(
              context: context,
              text: "PUESTA EN MARCHA",
              icon: Icons.build_outlined,
              onPressed: () => Navigator.pushNamed(context, '/puesta_en_marcha'),
            ),
            const SizedBox(height: 20),
            _buildHitachiButton(
              context: context,
              text: "GARANTÍA",
              icon: Icons.verified_outlined,
              onPressed: () => Navigator.pushNamed(context, '/garantia'),
            ),
          ],
        ),
      ),
    );
  }

  // Método existente (NO CAMBIAR)
  Widget _buildHitachiButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE00420),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.white, width: 1),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}