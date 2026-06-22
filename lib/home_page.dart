import 'package:flutter/material.dart';
import 'login_page.dart'; // bagian navigasi ke file login
import 'register_page.dart'; // import halaman register

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundShapes(), // bagian background shapes
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(),
                  _buildTopLogo(),
                  const SizedBox(height: 24),
                  _buildWelcomeText(),
                  const Spacer(),
                  _buildActionButtons(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -80,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBFCFBB).withOpacity(0.2),
            ),
          ),
        ),
        Positioned(
          top: 180,
          left: -120,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBFCFBB).withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          right: -50,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFBFCFBB).withOpacity(0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopLogo() {
    return Container(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/logo1.png',
        width: 110,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        const Text(
          'Selamat datang di,',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'KASTERA',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E392A),
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            // Navigasi standar ke halaman Login
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A6541),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Login',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            // Navigasi langsung ke halaman Register
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4A6541),
            side: const BorderSide(color: Color(0xFF4A6541), width: 2),
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            'Sign Up',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}