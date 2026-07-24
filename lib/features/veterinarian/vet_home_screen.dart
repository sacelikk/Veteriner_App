import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/chat_screen.dart';
import '../../services/fake_database.dart';

class VetHomeScreen extends ConsumerStatefulWidget {
  const VetHomeScreen({super.key});

  @override
  ConsumerState<VetHomeScreen> createState() => _VetHomeScreenState();
}

class _VetHomeScreenState extends ConsumerState<VetHomeScreen> {
  bool isOnline = false;

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Hekim Paneli'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.logout();
              if (!mounted) return;
              Navigator.pop(context); // TODO: Ana sayfaya yönlendir
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
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Müsaitlik Durumu',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isOnline ? 'Çevrimiçisiniz (Talepler açık)' : 'Çevrimdışısınız',
                          style: TextStyle(
                            color: isOnline ? Colors.green : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isOnline,
                      activeThumbColor: Colors.green,
                      onChanged: (value) {
                        setState(() {
                          isOnline = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Gelen Talepler Listesi
            const Text(
              'Gelen Destek Talepleri',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            if (!isOnline)
              const Expanded(
                child: Center(
                  child: Text(
                    'Talep alabilmek için çevrimiçi olmalısınız.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
                          return const Center(child: Text("Bekleyen talep yok."));
                        }
                        
                        return ListView.builder(
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.pets, color: Colors.white),
                                ),
                                title: Text(req['petOwnerName'] ?? 'Bilinmeyen Kullanıcı'),
                                subtitle: Text(
                                  req['problemDescription'] ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _acceptRequest(req['id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text('Kabul Et', style: TextStyle(color: Colors.white)),
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
