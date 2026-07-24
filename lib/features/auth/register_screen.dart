import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart'; // databaseProvider'ı buradan alıyoruz
import '../pet_owner/owner_home_screen.dart';
import '../veterinarian/vet_home_screen.dart';

class RegisterScreen extends ConsumerWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aramıza Katılın 🐾',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$role olarak hesap oluşturuyorsunuz.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Adınız Soyadınız',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                labelText: 'E-Posta Adresi',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Şifre',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty || passwordController.text.isEmpty || nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tüm alanları doldurun.')));
                  return;
                }

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesap oluşturuluyor...')));

                final db = ref.read(databaseProvider);
                try {
                  await db.registerWithEmail(
                    emailController.text.trim(),
                    passwordController.text.trim(),
                    nameController.text.trim(),
                    role,
                  );

                  if (!context.mounted) return;

                  if (role == "Pet Sahibi") {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerHomeScreen()),
                      (route) => false,
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const VetHomeScreen()),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kayıt Ol', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
