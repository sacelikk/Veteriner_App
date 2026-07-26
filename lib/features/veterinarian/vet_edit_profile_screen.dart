import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';

class VetEditProfileScreen extends ConsumerStatefulWidget {
  const VetEditProfileScreen({super.key});

  @override
  ConsumerState<VetEditProfileScreen> createState() => _VetEditProfileScreenState();
}

class _VetEditProfileScreenState extends ConsumerState<VetEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _clinicNameController;
  late TextEditingController _workingHoursController;
  late TextEditingController _bioController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final db = ref.read(databaseProvider);
    final user = db.currentUser;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _clinicNameController = TextEditingController(text: user?.clinicName ?? '');
    _workingHoursController = TextEditingController(text: user?.workingDaysHours ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clinicNameController.dispose();
    _workingHoursController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = ref.read(databaseProvider);
      await db.updateVetProfile(
        name: _nameController.text.trim(),
        clinicName: _clinicNameController.text.trim(),
        workingDaysHours: _workingHoursController.text.trim(),
        phone: '', // Telefon kaldırıldı
        address: '', // Adres kaldırıldı
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi!')),
      );
      Navigator.pop(context); // Go back after saving
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilimi Düzenle'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Hekim Bilgileri',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Ad Soyad',
                      icon: Icons.person,
                      validator: (val) => val == null || val.isEmpty ? 'Ad Soyad zorunludur' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _clinicNameController,
                      label: 'Klinik Adı',
                      icon: Icons.local_hospital,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _workingHoursController,
                      label: 'Çalışma Günleri & Saatleri',
                      icon: Icons.access_time,
                      hintText: 'Örn: Pzt-Cum 09:00 - 18:00',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Hakkında (Biyografi)',
                      icon: Icons.info_outline,
                      maxLines: 4,
                      hintText: 'Kendinizden ve uzmanlık alanlarınızdan bahsedin...',
                      validator: (val) {
                        if (val != null) {
                          // İçinde en az 7 rakam yan yana veya aralıklı geçiyorsa telefon numarası kabul et ve engelle
                          final digitCount = val.replaceAll(RegExp(r'[^0-9]'), '').length;
                          if (digitCount >= 7) {
                            return 'Güvenlik gereği biyografide telefon numarası veya iletişim bilgisi paylaşılamaz.';
                          }
                          // Adres ile ilgili kelimeleri engelle
                          final lower = val.toLowerCase();
                          if (lower.contains('mahalle') || lower.contains('sokak') || lower.contains('cadde') || lower.contains('adres:')) {
                            return 'Güvenlik gereği biyografide açık adres paylaşılamaz.';
                          }
                        }
                        return null;
                      }
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kaydet', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? hintText,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
