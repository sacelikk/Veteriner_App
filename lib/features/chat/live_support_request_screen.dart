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
  String? _selectedPetId;

  @override
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  void _requestSupport() async {
    if (_selectedPetId == null) {
      AnimatedDialog.show(
        context,
        title: 'Pet Seçilmedi',
        message: 'Lütfen destek almak istediğiniz petinizi seçin.',
        type: DialogType.info,
      );
      return;
    }

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
      requestId = await db.createSupportRequest(_problemController.text.trim(), petId: _selectedPetId);
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: myPetsAsync.when(
                  data: (pets) {
                    if (pets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Text('Lütfen önce bir evcil hayvan ekleyin.', style: TextStyle(color: Colors.red)),
                      );
                    }
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.pets, color: AppTheme.primaryColor),
                        border: InputBorder.none,
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                      hint: const Text('Pet Seçin', style: TextStyle(color: AppTheme.textLight)),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      value: _selectedPetId,
                      items: pets.map((pet) {
                        return DropdownMenuItem<String>(
                          value: pet.id,
                          child: Text('${pet.name} (${pet.type})', style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedPetId = newValue;
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator())),
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
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _problemController,
                  maxLines: 4,
                  style: const TextStyle(fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Örn: Tarçın sabahtan beri çok halsiz ve yemek yemiyor...',
                    hintStyle: TextStyle(color: Colors.black38),
                    border: InputBorder.none,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Çevrimiçi Hekim Bul', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
