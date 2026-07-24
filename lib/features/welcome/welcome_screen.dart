import 'package:flutter/material.dart';
import 'package:vetapp/features/auth/login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Kısım: Logo veya İkon Alanı
              const Icon(
                Icons.pets, // Şimdilik basit bir pati ikonu koyalım
                size: 100,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              
              // Başlık
              const Text(
                'BaytarAPP',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Evcil dostunuz için anında uzman desteği',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),

              // 1. Buton: Pet Sahibi
               OutlinedButton(
                onPressed: () {
                  // TODO: Veteriner giriş sayfasına yönlendirilecek
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: "Pet Sahibi"),
                    ),
                  );
                }},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Pet Sahibiyim',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              
              const SizedBox(height: 16),

              // 2. Buton: Veteriner Hekim
              OutlinedButton(
                onPressed: () {
                  // TODO: Veteriner giriş sayfasına yönlendirilecek
                {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: "Veteriner Hekim"),
                    ),
                  );
                }},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Veteriner Hekimim',
                  style: TextStyle(fontSize: 18, color: Colors.teal),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}