import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pet_owner/owner_home_screen.dart';
import '../veterinarian/vet_home_screen.dart';
import '../../services/fake_database.dart';

class LoginScreen extends ConsumerWidget {
  final String role; 

  const LoginScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // E-posta ve şifre için geçici controllerlar
    final emailController = TextEditingController(text: "test@baytar.app");
    final passwordController = TextEditingController(text: "123456");

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Giriş Yap'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Merhaba $role 👋',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Devam etmek için lütfen giriş yapın.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-Posta Adresi',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: const Icon(Icons.visibility_off), 
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                // Riverpod ile login fonksiyonunu çağıralım
                final db = ref.read(databaseProvider);
                
                // Yükleniyor efekti için basit bir bekleme (Sahte Backend)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Giriş yapılıyor...')),
                );
                
                await db.login(emailController.text, role);

                if (!context.mounted) return; // Context hatasını önlemek için eklendi

                if (role == "Pet Sahibi") {
                  Navigator.pushReplacement( 
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OwnerHomeScreen(),
                    ),
                  );
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VetHomeScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Giriş Yap',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}