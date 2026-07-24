import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'add_pet_screen.dart';
import '../chat/live_support_request_screen.dart';
import '../../services/fake_database.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pet listesini Riverpod'dan dinliyoruz
    final myPetsAsyncValue = ref.watch(myPetsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('BaytarAPP'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.teal[50],
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(Icons.support_agent, size: 48, color: Colors.teal),
                    const SizedBox(height: 16),
                    const Text(
                      'Veteriner hekimlerimiz çevrimiçi!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LiveSupportRequestScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.video_camera_front, color: Colors.white),
                      label: const Text(
                        'Canlı Destek Al',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Evcil Hayvanlarım',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  child: const Text('+ Yeni Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Riverpod ile veritabanından çekilen petleri gösteriyoruz
            Expanded(
              child: myPetsAsyncValue.when(
                data: (pets) {
                  if (pets.isEmpty) {
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.pets, color: Colors.white),
                        ),
                        title: Text('Henüz bir evcil hayvan eklemediniz'),
                        subtitle: Text('Kayıt oluşturmak için + Yeni Ekle butonuna tıklayın.'),
                      ),
                    );
                  }

                  // Eğer pet varsa liste olarak göster
                  return ListView.builder(
                    itemCount: pets.length,
                    itemBuilder: (context, index) {
                      final pet = pets[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              pet.type == 'Kedi' ? '🐱' : (pet.type == 'Köpek' ? '🐶' : '🐾'),
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          title: Text(pet.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${pet.type} • ${pet.age} Yaşında • ${pet.weight} kg'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // TODO: Silme işlemi
                            },
                          ),
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
    );
  }
}