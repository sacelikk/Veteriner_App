import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';
import '../welcome/welcome_screen.dart';
import '../chat/my_chats_screen.dart';
import '../chat/adoption_chat_screen.dart';
import 'add_adoption_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

class AdoptionsFeedScreen extends ConsumerWidget {
  const AdoptionsFeedScreen({super.key});

  Widget _buildAvatar(String species, String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http') || photoUrl.startsWith('https')) {
        return CircleAvatar(
          radius: 30,
          backgroundImage: NetworkImage(photoUrl),
          backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
        );
      }
    }
    
    String emoji = '🐾';
    if (species.toLowerCase().contains('kedi')) emoji = '🐱';
    if (species.toLowerCase().contains('köpek')) emoji = '🐶';
    if (species.toLowerCase().contains('kuş')) emoji = '🦜';
    if (species.toLowerCase().contains('tavşan')) emoji = '🐰';

    return CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
      child: Text(emoji, style: const TextStyle(fontSize: 28)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adoptionsAsync = ref.watch(adoptionsProvider);
    final db = ref.watch(databaseProvider);
    final isGuest = db.currentUser?.isGuest ?? true;

    return Scaffold(
      backgroundColor: Colors.transparent, // TabBarView içinde olduğu için
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tüm İlanlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
              ],
            ),
          ),
          Expanded(
            child: adoptionsAsync.when(
              data: (adoptions) {
          if (adoptions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets9.lottiefiles.com/packages/lf20_0s6g2m.json', // Search/Empty Lottie
                    width: 150,
                    errorBuilder: (c, e, s) => Icon(Icons.pets, size: 64, color: AppTheme.primaryLight.withOpacity(0.5)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Şu an sahiplendirilecek dostumuz yok.',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return AnimationLimiter(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adoptions.length,
              itemBuilder: (context, index) {
                final adoption = adoptions[index];
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAvatar(adoption.species, adoption.photoUrl),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  adoption.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: AppTheme.textLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      adoption.location,
                                      style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Info chips
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              adoption.species,
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              adoption.age,
                              style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        adoption.description,
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 14, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'İlan Sahibi: ${adoption.ownerName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                              ),
                              Text(
                                DateFormat('dd.MM.yyyy').format(adoption.createdAt.toDate()),
                                style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isGuest) {
                                AnimatedDialog.show(
                                  context,
                                  title: 'Misafir Girişi',
                                  message: 'İlan sahibiyle mesajlaşmak için lütfen giriş yapın.',
                                  type: DialogType.info,
                                  onConfirm: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                                      (route) => false,
                                    );
                                  },
                                );
                                if (adoption.ownerId == db.currentUser?.id) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Kendi ilanınıza mesaj atamazsınız.')),
                                  );
                                  return;
                                }

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator()),
                                );
                                
                                db.createOrGetAdoptionChat(
                                  peerId: adoption.ownerId,
                                  peerName: adoption.ownerName,
                                  adoptionId: adoption.id,
                                  adoptionTitle: adoption.title,
                                ).then((chatId) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // close loader
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AdoptionChatScreen(
                                          chatId: chatId,
                                          peerName: adoption.ownerName,
                                          adoptionTitle: adoption.title,
                                        ),
                                      ),
                                    );
                                  }
                                }).catchError((e) {
                                  if (context.mounted) {
                                    Navigator.pop(context); // close loader
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                                  }
                                });
                              }
                            },
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: const Text('Mesaj At'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ), // Row
                    ], // Column children
                  ), // Column
                ), // Padding
              ), // Card
            ), // FadeInAnimation
          ), // SlideAnimation
        ); // AnimationConfiguration
      }, // itemBuilder
    ), // ListView
  ); // AnimationLimiter
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (isGuest) {
            AnimatedDialog.show(
              context,
              title: 'Kayıt Olmanız Gerekiyor',
              message: 'İlan verebilmek için lütfen bir hesap oluşturun veya giriş yapın.',
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
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAdoptionScreen()),
            );
          }
        },
        backgroundColor: AppTheme.accentColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('İlan Ver', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
