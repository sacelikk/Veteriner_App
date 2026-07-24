import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_pet_screen.dart';
import '../chat/live_support_request_screen.dart';
import '../../services/fake_database.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';
import '../welcome/welcome_screen.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  void _showGuestWarning(BuildContext context) {
    AnimatedDialog.show(
      context,
      title: 'Kayıt Olmanız Gerekiyor',
      message: 'Canlı destek almak veya pet kaydı oluşturmak için lütfen bir hesap oluşturun veya giriş yapın.',
      type: DialogType.info,
      buttonText: 'Giriş Yap / Kayıt Ol',
      onConfirm: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final currentUser = db.currentUser;
    final isGuest = currentUser?.isGuest ?? true;

    final myPetsAsyncValue = ref.watch(myPetsProvider);
    final vetsAsyncValue = ref.watch(veterinariansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(isGuest ? 'BaytarAPP (Misafir)' : 'BaytarAPP'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(isGuest ? Icons.login : Icons.logout),
            tooltip: isGuest ? 'Giriş Yap' : 'Çıkış Yap',
            onPressed: () async {
              await db.logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Premium Destek Kartı
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.9),
                    AppTheme.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.pets, size: 120, color: Colors.white.withOpacity(0.1)),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Icon(Icons.support_agent, size: 48, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Veteriner hekimlerimiz çevrimiçi!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (isGuest) {
                              _showGuestWarning(context);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LiveSupportRequestScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.video_camera_front, color: AppTheme.primaryColor),
                          label: const Text(
                            'Hemen Canlı Destek Al',
                            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            elevation: 5,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Misafir / Normal Kullanıcı İçerik Bölümü
            if (isGuest) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktif Veteriner Hekimlerimiz',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '● Çevrimiçi',
                      style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: vetsAsyncValue.when(
                  data: (vets) {
                    return ListView.builder(
                      itemCount: vets.length,
                      itemBuilder: (context, index) {
                        final vet = vets[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.medical_services, color: AppTheme.primaryColor, size: 28),
                            ),
                            title: Text(vet.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: const Padding(
                              padding: EdgeInsets.only(top: 4.0),
                              child: Text('Nöbetçi Hekim\n7/24 Aktif', style: TextStyle(color: AppTheme.textLight, fontSize: 12, height: 1.3)),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _showGuestWarning(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: const Text('İletişim', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Hata: $err')),
                ),
              ),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Evcil Hayvanlarım',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddPetScreen(),
                        ),
                      );
                    },
                    child: const Text('+ Yeni Ekle', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: myPetsAsyncValue.when(
                  data: (pets) {
                    if (pets.isEmpty) {
                      return Card(
                        child: const ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primaryColor,
                            child: Icon(Icons.pets, color: Colors.white),
                          ),
                          title: Text('Henüz bir evcil hayvan eklemediniz', style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Kayıt oluşturmak için + Yeni Ekle butonuna tıklayın.'),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: pets.length,
                      itemBuilder: (context, index) {
                        final pet = pets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppTheme.accentColor,
                              child: Text(
                                pet.type == 'Kedi' ? '🐱' : (pet.type == 'Köpek' ? '🐶' : '🐾'),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('${pet.type} • ${pet.age} Yaşında • ${pet.weight} kg', style: const TextStyle(color: AppTheme.textLight)),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Hata: $error'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}