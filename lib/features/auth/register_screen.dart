import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart'; 
import '../pet_owner/owner_home_screen.dart';
import '../veterinarian/vet_home_screen.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends ConsumerWidget {
  final String role;

  const RegisterScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Aramıza Katılın 🐾',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              '$role olarak hesap oluşturuyorsunuz.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textLight),
            ),
            const SizedBox(height: 40),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Adınız Soyadınız',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Posta Adresi',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 32),
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
                      child: const Text('Kayıt Ol'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
