import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';
import 'chat_screen.dart';

class LiveSupportRequestScreen extends ConsumerStatefulWidget {
  const LiveSupportRequestScreen({super.key});

  @override
  ConsumerState<LiveSupportRequestScreen> createState() => _LiveSupportRequestScreenState();
}

class _LiveSupportRequestScreenState extends ConsumerState<LiveSupportRequestScreen> {
  final TextEditingController _problemController = TextEditingController();

  void _requestSupport() async {
    if (_problemController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen sorunu kısaca tarif edin.')));
      return;
    }

    final db = ref.read(databaseProvider);
    
    // 1. Talebi oluştur ve requestId'yi al
    String requestId = '';
    try {
      requestId = await db.createSupportRequest(_problemController.text.trim());
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Canlı Destek Talebi'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hangi petiniz için destek almak istiyorsunuz?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Şimdilik sahte bir dropdown ile pet seçimi
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.pets),
              ),
              hint: const Text('Pet Seçin'),
              items: ['Tarçın (Köpek)', 'Mia (Kedi)'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {},
            ),
            const SizedBox(height: 24),

            const Text(
              'Sorunu Kısaca Tarif Edin',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _problemController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Örn: Tarçın sabahtan beri çok halsiz ve yemek yemiyor...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Fotoğraf veya Video Ekle (İsteğe Bağlı)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // TODO: Galeri veya kameradan medya seçimi
              },
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.teal, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 32, color: Colors.teal),
                    SizedBox(height: 8),
                    Text('Medya Yükle', style: TextStyle(color: Colors.teal)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Hekim Bul Butonu
            ElevatedButton(
              onPressed: _requestSupport,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Çevrimiçi Hekim Bul',
                style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
              ),
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
          // Veteriner kabul etti! Dialog'u kapatıp Chat ekranına yönlendir.
          // Build içerisinde doğrudan Navigator çağırmak sakıncalı olabileceği için 
          // addPostFrameCallback kullanıyoruz.
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              const Text(
                'Boşta olan bir veteriner hekim aranıyor...\nLütfen bekleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // TODO: Talebi iptal et
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
