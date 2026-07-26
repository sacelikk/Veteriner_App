import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/my_chats_screen.dart';
import '../chat/chat_screen.dart';
import '../chat/my_chats_screen.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import '../welcome/welcome_screen.dart';
import 'vet_edit_profile_screen.dart';

class VetHomeScreen extends ConsumerStatefulWidget {
  const VetHomeScreen({super.key});

  @override
  ConsumerState<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends ConsumerState<VetHomeScreen> {
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    // İlk açılışta mevcut durumu FirebaseService'den al
    final db = ref.read(databaseProvider);
    isOnline = db.currentUser?.isOnline ?? false;
  }

  void _acceptRequest(String requestId) async {
    final db = ref.read(databaseProvider);
    try {
      await db.acceptSupportRequest(requestId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(role: "Veteriner Hekim", chatId: requestId),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hekim Paneli'),
        automaticallyImplyLeading: false,
        actions: [
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
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.logout();
              if (!mounted) return;
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
            // Durum Değiştirme Kartı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Müsaitlik Durumu',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline ? 'Çevrimiçisiniz (Talepler açık)' : 'Çevrimdışısınız',
                          style: TextStyle(
                            color: isOnline ? Colors.green.shade600 : AppTheme.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeColor: Colors.green.shade600,
                      onChanged: (value) async {
                        setState(() {
                          isOnline = value;
                        });
                        final db = ref.read(databaseProvider);
                        await db.updateOnlineStatus(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Profilimi Düzenle ve Mesajlarım Butonları
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VetEditProfileScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Profili Düzenle'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyChatsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.inbox, size: 18),
                    label: const Text('Mesajlarım'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Gelen Talepler Listesi
            Text(
              'Gelen Destek Talepleri',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (!isOnline)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bedtime, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Talep alabilmek için çevrimiçi olmalısınız.',
                        style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Consumer(
                  builder: (context, ref, child) {
                    final requestsAsync = ref.watch(pendingRequestsProvider);

                    return requestsAsync.when(
                      data: (requests) {
                        if (requests.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.inbox, size: 64, color: AppTheme.textLight.withOpacity(0.5)),
                                const SizedBox(height: 16),
                                Text(
                                  "Şu an bekleyen talep yok.",
                                  style: TextStyle(color: AppTheme.textLight, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: AppTheme.accentColor,
                                    radius: 24,
                                    child: Icon(Icons.pets, color: Colors.white),
                                  ),
                                  title: Text(
                                    req['petOwnerName'] ?? 'Bilinmeyen Kullanıcı',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      req['problemDescription'] ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: AppTheme.textLight),
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _acceptRequest(req['id']),
                                    child: const Text('Kabul Et'),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Hata: $e')),
                    );
                  }
                ),
              ),
          ],
        ),
      ),
    );
  }
}
