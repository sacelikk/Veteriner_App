import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/login_screen.dart';
import '../pet_owner/owner_home_screen.dart';
import '../veterinarian/vet_home_screen.dart';
import '../../services/fake_database.dart'; // firebase service proxy

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final db = ref.read(databaseProvider);
    final user = await db.checkCurrentUser();
    if (user != null && mounted) {
      if (user.role == "Pet Sahibi") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OwnerHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const VetHomeScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Üst Kısım: Logo ve Karşılama
              const Icon(
                Icons.pets,
                size: 80,
                color: Colors.teal,
              ),
              const SizedBox(height: 24),
              const Text(
                'BaytarAPP\'e Hoşgeldiniz',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Lütfen devam etmek için rolünüzü seçin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),

              // Pet Sahibi Butonu
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: "Pet Sahibi"),
                    ),
                  );
                },
                icon: const Icon(Icons.person, color: Colors.white),
                label: const Text(
                  'Pet Sahibiyim',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Veteriner Hekim Butonu
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(role: "Veteriner Hekim"),
                    ),
                  );
                },
                icon: const Icon(Icons.medical_services, color: Colors.teal),
                label: const Text(
                  'Veteriner Hekimim',
                  style: TextStyle(fontSize: 18, color: Colors.teal),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.teal, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}