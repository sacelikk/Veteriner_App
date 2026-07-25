import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';
import 'chat_screen.dart';

class LiveSupportRequestScreen extends ConsumerStatefulWidget {
  const LiveSupportRequestScreen({super.key});

  @override
  ConsumerState<LiveSupportRequestScreen> createState() => _LiveSupportRequestScreenState();
}

class _LiveSupportRequestScreenState extends ConsumerState<LiveSupportRequestScreen> {
  final TextEditingController _problemController = TextEditingController();

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  void _requestSupport() async {
    if (_problemController.text.trim().isEmpty) {
      AnimatedDialog.show(
        context,
        title: 'Açıklama Eksik',
        message: 'Lütfen petinizin sorununu kısaca tarif edin.',
        type: DialogType.info,
      );
      return;
    }

    final db = ref.read(databaseProvider);
    
    String requestId = '';
    try {
      requestId = await db.createSupportRequest(_problemController.text.trim());
    } catch (e) {
      if (!mounted) return;
      AnimatedDialog.show(
        context,
        title: 'Talep Oluşturulamadı',
        message: e.toString().replaceAll('Exception: ', ''),
        type: DialogType.error,
      );
      return;
    }

    if (!mounted) return;

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
                child: Consumer(
                  builder: (context, ref, child) {
                    final petsAsync = ref.watch(myPetsProvider);
                    return petsAsync.when(
                      data: (pets) {
                        final itemsList = pets.isEmpty
                            ? ['Genel Sağlık Danışmanlığı']
                            : pets.map((p) => '${p.name} (${p.type})').toList();
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.pets),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          hint: const Text('Pet Seçin'),
                          items: itemsList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {},
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.pets),
                          border: InputBorder.none,
                        ),
                        hint: const Text('Genel Sağlık Danışmanlığı'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Genel Sağlık Danışmanlığı',
                            child: Text('Genel Sağlık Danışmanlığı'),
                          )
                        ],
                        onChanged: (v) {},
                      ),
                    );
                  },
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
                    hintText: 'Örn: Evcil hayvanım sabahtan beri halsiz ve yemek yemiyor...',
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
                AnimatedDialog.show(
                  context,
                  title: 'Medya Seçimi',
                  message: 'Fotoğraf veya video yükleme yakında aktifleştirilecektir.',
                  type: DialogType.info,
                );
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
            Navigator.pop(context);
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
