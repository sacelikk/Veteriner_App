import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/my_chats_screen.dart';
import '../chat/chat_screen.dart';
import 'add_pet_screen.dart';
import '../chat/live_support_request_screen.dart';
import '../veterinarian/vet_profile_screen.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';
import 'package:intl/intl.dart';
import 'pet_details_screen.dart';
import 'adoptions_feed_screen.dart';
import '../welcome/welcome_screen.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:lottie/lottie.dart';

class OwnerHomeScreen extends ConsumerStatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  ConsumerState<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends ConsumerState<OwnerHomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Widget _buildPetAvatar(String type, String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('http') || photoUrl.startsWith('https')) {
        return CircleAvatar(
          backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
          backgroundImage: NetworkImage(photoUrl),
        );
      } else {
        return CircleAvatar(
          backgroundColor: AppTheme.accentColor.withOpacity(0.2),
          child: Text(photoUrl, style: const TextStyle(fontSize: 24)),
        );
      }
    }
    String emoji = '🐾';
    if (type == 'Kedi') emoji = '🐱';
    if (type == 'Köpek') emoji = '🐶';
    if (type == 'Kuş') emoji = '🦜';
    if (type == 'Tavşan') emoji = '🐰';

    return CircleAvatar(
      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
      child: Text(emoji, style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final currentUser = db.currentUser;
    final isGuest = currentUser?.isGuest ?? true;

    final myPetsAsyncValue = ref.watch(myPetsProvider);
    final vetsAsyncValue = ref.watch(veterinariansProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(isGuest ? 'BaytarAPP (Misafir)' : 'BaytarAPP'),
        automaticallyImplyLeading: false,
        actions: [
          if (!isGuest)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Mesajlarım',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyChatsScreen()),
                );
              },
            ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          tabs: const [
            Tab(icon: Icon(Icons.pets), text: 'Evcil Hayvanlarım'),
            Tab(icon: Icon(Icons.favorite), text: 'Sahiplendirme'),
            Tab(icon: Icon(Icons.medical_services), text: 'Veteriner Hekimlerimiz'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Destek Kartı
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              color: AppTheme.primaryLight.withOpacity(0.1),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppTheme.primaryLight.withOpacity(0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      radius: 22,
                      child: Icon(Icons.support_agent, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            '7/24 Nöbetçi Veterinerler',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                          ),
                          Text(
                            'Canlı destek ve görüntülü danışmanlık',
                            style: TextStyle(fontSize: 12, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Canlı Destek', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // TabView Bölümü
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Tab: Evcil Hayvanlarım
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Yaklaşan Kontroller Kartı (Sadece giriş yapmışsa)
                      if (!isGuest)
                        Consumer(
                          builder: (context, ref, child) {
                            final upcomingAsync = ref.watch(upcomingVaccinesProvider);
                            
                            return upcomingAsync.when(
                              data: (vaccines) {
                                if (vaccines.isEmpty) return const SizedBox.shrink();
                                
                                return Card(
                                  color: Colors.orange.shade50,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(color: Colors.orange.shade300, width: 1),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.notification_important, color: Colors.orange.shade800, size: 20),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Yaklaşan Kontroller (${vaccines.length})',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...vaccines.take(2).map((v) => Padding(
                                          padding: const EdgeInsets.only(top: 4.0),
                                          child: Text(
                                            '• ${v.name} (${DateFormat('dd.MM.yyyy').format(v.nextDueDate)})',
                                            style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                                          ),
                                        )).toList(),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                        ),
                        
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kayıtlı Hayvanlarım',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              if (isGuest) {
                                _showGuestWarning(context);
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddPetScreen(),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Yeni Ekle', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: isGuest
                            ? Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.pets, size: 54, color: AppTheme.primaryLight),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Evcil Hayvan Kaydı İçin Giriş Yapın',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Petlerinizin aşı takvimini, kilosunu, ırk ve mikroçip bilgilerini kaydetmek için oturum açabilirsiniz.',
                                        style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () => _showGuestWarning(context),
                                        child: const Text('Giriş Yap / Kayıt Ol'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : myPetsAsyncValue.when(
                                data: (pets) {
                                  if (pets.isEmpty) {
                                    return Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(24.0),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.pets, size: 48, color: AppTheme.primaryLight),
                                            const SizedBox(height: 12),
                                            const Text(
                                              'Henüz bir evcil hayvan eklemediniz',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text(
                                              'Evcil hayvanınızın fotoğrafı, ırkı, aşısı ve detayları ile kaydını hemen oluşturun.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(builder: (context) => const AddPetScreen()),
                                                );
                                              },
                                              icon: const Icon(Icons.add),
                                              label: const Text('Evcil Hayvan Ekle'),
                                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: pets.length,
                                    itemBuilder: (context, index) {
                                      final pet = pets[index];
                                      return Card(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        child: ExpansionTile(
                                          leading: _buildPetAvatar(pet.type, pet.photoUrl),
                                          title: Text(
                                            pet.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          subtitle: Text(
                                            '${pet.type} ${pet.breed != null ? "• ${pet.breed}" : ""} • ${pet.age} Yaş • ${pet.weight} kg',
                                            style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                                          ),
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Divider(),
                                                  if (pet.gender != null)
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.badge, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 6),
                                                        Text('Cinsiyet: ${pet.gender}', style: const TextStyle(fontSize: 13)),
                                                      ],
                                                    ),
                                                  if (pet.isNeutered != null) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.health_and_safety, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          'Kısırlaştırma: ${pet.isNeutered! ? "Evet" : "Hayır"}',
                                                          style: const TextStyle(fontSize: 13),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (pet.microchipNo != null && pet.microchipNo!.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.qr_code, size: 16, color: AppTheme.primaryColor),
                                                        const SizedBox(width: 6),
                                                        Text('Mikroçip No: ${pet.microchipNo}', style: const TextStyle(fontSize: 13)),
                                                      ],
                                                    ),
                                                  ],
                                                  if (pet.allergies != null && pet.allergies!.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            'Alerji/Sağlık: ${pet.allergies}',
                                                            style: const TextStyle(fontSize: 13, color: Colors.orange),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  if (pet.notes != null && pet.notes!.isNotEmpty) ...[
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.note, size: 16, color: AppTheme.textLight),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text('Notlar: ${pet.notes}', style: const TextStyle(fontSize: 13)),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                  const SizedBox(height: 12),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => PetDetailsScreen(pet: pet),
                                                          ),
                                                        );
                                                      },
                                                      icon: const Icon(Icons.monitor_heart, size: 18),
                                                      label: const Text('Sağlık ve Aşı Kayıtlarını Gör'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.white,
                                                        foregroundColor: AppTheme.primaryColor,
                                                        elevation: 1,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
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
                  ),
                ),

                // 2. Tab: Sahiplendirme (Adoptions)
                const AdoptionsFeedScreen(),
                
                // 3. Tab: Veteriner Hekimlerimiz & Klinikler
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nöbetçi & Aktif Veterinerler',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
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
                            if (vets.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Lottie.network(
                                        'https://assets9.lottiefiles.com/packages/lf20_0s6g2m.json', // Search/Empty Lottie
                                        width: 150,
                                        errorBuilder: (c, e, s) => const Icon(Icons.medical_services_outlined, size: 48, color: AppTheme.primaryLight),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Kayıtlı Veteriner Hekim Bulunmuyor',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Sisteme henüz veteriner hekim kaydı eklenmemiştir.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: AppTheme.textLight, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return AnimationLimiter(
                              child: ListView.builder(
                                itemCount: vets.length,
                                itemBuilder: (context, index) {
                                  final vet = vets[index];
                                  final ratingText = vet.rating.toStringAsFixed(1);
                                  return AnimationConfiguration.staggeredList(
                                    position: index,
                                    duration: const Duration(milliseconds: 500),
                                    child: SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(
                                        child: Card(
                                          margin: const EdgeInsets.only(bottom: 12),
                                          elevation: 3,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => VetProfileScreen(vet: vet),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(16),
                                            child: Padding(
                                              padding: const EdgeInsets.all(14.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      CircleAvatar(
                                                        radius: 26,
                                                        backgroundColor: AppTheme.primaryLight,
                                                        child: Text(
                                                          vet.name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join(),
                                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              vet.name,
                                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                            ),
                                                            Text(
                                                              vet.clinicName ?? 'Klinik Bilgisi Yok',
                                                              style: const TextStyle(color: AppTheme.textLight, fontSize: 13),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: Colors.amber.shade100,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Row(
                                                          children: [
                                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              ratingText,
                                                              style: TextStyle(
                                                                color: Colors.amber.shade900,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 13,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '(${vet.reviewCount})',
                                                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const Divider(height: 20),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                                                      const SizedBox(width: 6),
                                                      Expanded(
                                                        child: Text(
                                                          vet.workingDaysHours ?? 'Çalışma saatleri belirtilmedi',
                                                          style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        vet.isOnline ? '● Müsait (Çevrimiçi)' : '○ Çevrimdışı',
                                                        style: TextStyle(
                                                          color: vet.isOnline ? Colors.green : Colors.grey,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                      ElevatedButton.icon(
                                                        onPressed: () {
                                                          Navigator.push(
                                                            context,
                                                            MaterialPageRoute(
                                                              builder: (context) => VetProfileScreen(vet: vet),
                                                            ),
                                                          );
                                                        },
                                                        icon: const Icon(Icons.person_search, size: 16),
                                                        label: const Text('Profil & Yorumlar', style: TextStyle(fontSize: 12)),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: AppTheme.primaryColor,
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (err, stack) => Center(child: Text('Hata: $err')),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
