import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart';
import '../../models/pet_model.dart';

class LiveSupportRequestScreen extends ConsumerStatefulWidget {
  const LiveSupportRequestScreen({super.key});

  @override
  ConsumerState<LiveSupportRequestScreen> createState() => _LiveSupportRequestScreenState();
}

class _LiveSupportRequestScreenState extends ConsumerState<LiveSupportRequestScreen> {
  final TextEditingController _problemController = TextEditingController();
  PetModel? _selectedPet;

  void _requestSupport() async {
    if (_selectedPet == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir pet seçin.')));
      return;
    }

    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sorunu kısaca tarif edin.')));
      return;
    }

    final db = ref.read(databaseProvider);
    
    // 1. Talebi oluştur ve requestId'yi al
    String requestId = '';
    try {
      requestId = await db.createSupportRequest(
        "Pet: ${_selectedPet!.name} (${_selectedPet!.type})\nSorun: ${_problemController.text.trim()}"
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      return;
    }

    if (!mounted) return;

    // 2. Bekleme ekranını (Dialog) göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _WaitingForVetDialog(requestId: requestId);
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final myPetsAsync = ref.watch(myPetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Canlı Destek Talebi'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hangi petiniz için destek almak istiyorsunuz?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: myPetsAsync.when(
                  data: (pets) {
                    if (pets.isEmpty) {
                      return const Text("Önce profilinizden pet eklemelisiniz.", style: TextStyle(color: Colors.red));
                    }
                    return DropdownButtonFormField<PetModel>(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pets),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      hint: const Text('Pet Seçin'),
                      value: _selectedPet,
                      items: pets.map((pet) {
                        return DropdownMenuItem<PetModel>(
                          value: pet,
                          child: Text('${pet.name} (${pet.type})'),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPet = newValue;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Hata: $e'),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Sorunu Kısaca Tarif Edin',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _problemController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Örn: Tarçın sabahtan beri çok halsiz ve yemek yemiyor...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Fotoğraf veya Video Ekle (İsteğe Bağlı)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // TODO: Galeri veya kameradan medya seçimi
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppTheme.primaryLight, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 32, color: AppTheme.primaryLight),
                    SizedBox(height: 8),
                    Text('Medya Yükle', style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Hekim Bul Butonu
            ElevatedButton(
              onPressed: _requestSupport,
              child: const Text('Çevrimiçi Hekim Bul'),
            ),
          ],
        ),
      ),
    );
  }
}

// Özel Bekleme Dialog'u (Provider'ı dinleyip durum 'accepted' olunca sayfayı değiştirir)
class _WaitingForVetDialog extends ConsumerWidget {
  final String requestId;
  const _WaitingForVetDialog({required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(supportRequestStatusProvider(requestId));

    return statusAsync.when(
      data: (statusData) {
        if (statusData != null && statusData['status'] == 'accepted') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pop(context); // Dialog'u kapat
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(role: "Pet Sahibi", chatId: requestId),
              ),
            );
          });
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                'Boşta olan bir veteriner hekim aranıyor...\nLütfen bekleyin.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('İptal Et', style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        );
      },
      loading: () => const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))),
      error: (e, s) => AlertDialog(content: Text('Hata: $e')),
    );
  }
}
