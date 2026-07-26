import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import '../../services/database_providers.dart';
import '../../models/pet_model.dart';
import '../../theme/app_theme.dart';
import '../../theme/animated_dialog.dart';

class AddPetScreen extends ConsumerStatefulWidget {
  const AddPetScreen({super.key});

  @override
  ConsumerState<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends ConsumerState<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController(text: 'Kedi');
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // Opsiyonel Alanlar
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _microchipController = TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _photoUrlController = TextEditingController();

  String _gender = 'Erkek'; // Erkek / Dişi
  bool _isNeutered = false; // Kısırlaştırılmış mı
  String _selectedAvatar = '🐱'; // Varsayılan Profil İkonu
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        // Resim seçildiyse emoji seçimini iptal gibi göstermek için silebiliriz ama kalsın
      });
    }
  }

  final List<String> _avatarPresets = ['🐱', '🐶', '🦜', '🐰', '🐹', '🐾'];

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _breedController.dispose();
    _microchipController.dispose();
    _allergiesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePet() async {
    if (_nameController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _weightController.text.trim().isEmpty) {
      AnimatedDialog.show(
        context,
        title: 'Eksik Bilgi',
        message: 'Lütfen petinizin adını, yaşını ve kilosunu doldurun.',
        type: DialogType.info,
      );
      return;
    }

    final db = ref.read(databaseProvider);
    final currentUser = db.currentUser;
    
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String photo = _selectedAvatar;
      if (_selectedImage != null) {
        final imagePath = 'pets/${const Uuid().v4()}.jpg';
        final uploadedUrl = await db.uploadImageToStorage(_selectedImage!, imagePath);
        if (uploadedUrl != null) {
          photo = uploadedUrl;
        }
      }

      final newPet = PetModel(
        id: Random().nextInt(10000).toString(),
        ownerId: currentUser.id,
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 1,
        weight: double.tryParse(_weightController.text.trim()) ?? 1.0,
        breed: _breedController.text.trim().isEmpty ? null : _breedController.text.trim(),
        gender: _gender,
        isNeutered: _isNeutered,
        microchipNo: _microchipController.text.trim().isEmpty ? null : _microchipController.text.trim(),
        allergies: _allergiesController.text.trim().isEmpty ? null : _allergiesController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        photoUrl: photo,
      );

      await db.addPet(newPet);
      ref.invalidate(myPetsProvider);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      AnimatedDialog.show(
        context,
        title: 'Pet Eklendi 🐾',
        message: '${newPet.name} başarıyla evcil hayvanlarınız arasına eklendi.',
        type: DialogType.success,
        onConfirm: () {
          Navigator.pop(context);
        },
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      AnimatedDialog.show(
        context,
        title: 'Hata Oluştu',
        message: e.toString().replaceAll('Exception: ', ''),
        type: DialogType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Yeni Evcil Hayvan Ekle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profil Fotoğrafı / Avatar Seçimi Bölümü
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Pet Profil Fotoğrafı / İkonu Seçin',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.accentColor.withOpacity(0.2),
                      child: Text(
                        _selectedAvatar,
                        style: const TextStyle(fontSize: 42),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: _avatarPresets.map((avatar) {
                        final isSelected = avatar == _selectedAvatar;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatar = avatar;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryLight.withOpacity(0.3) : Colors.transparent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Text(avatar, style: const TextStyle(fontSize: 26)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo, color: AppTheme.primaryColor.withOpacity(0.6)),
                                  const SizedBox(height: 4),
                                  const Text('Galeriden Gerçek Fotoğraf Seç (Opsiyonel)', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Temel Zorunlu Bilgiler Kartı
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Temel Bilgiler (Zorunlu)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Petinizin Adı *',
                        prefixIcon: const Icon(Icons.pets),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: _typeController.text,
                      decoration: InputDecoration(
                        labelText: 'Türü *',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Kedi', 'Köpek', 'Kuş', 'Tavşan', 'Diğer'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _typeController.text = newValue;
                            if (newValue == 'Kedi') _selectedAvatar = '🐱';
                            if (newValue == 'Köpek') _selectedAvatar = '🐶';
                            if (newValue == 'Kuş') _selectedAvatar = '🦜';
                            if (newValue == 'Tavşan') _selectedAvatar = '🐰';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ageController,
                            decoration: InputDecoration(
                              labelText: 'Yaşı *',
                              prefixIcon: const Icon(Icons.cake),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: TextField(
                            controller: _weightController,
                            decoration: InputDecoration(
                              labelText: 'Kilo (kg) *',
                              prefixIcon: const Icon(Icons.monitor_weight),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // İsteğe Bağlı Detaylı Bilgiler Kartı (Opsiyonel)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Spesifik Detaylar',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'İsteğe Bağlı',
                            style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _breedController,
                      decoration: InputDecoration(
                        labelText: 'Irkı / Cinsi (İsteğe Bağlı)',
                        hintText: 'örn: Tekir, British Shorthair, Kangal',
                        prefixIcon: const Icon(Icons.pets_sharp),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: InputDecoration(
                              labelText: 'Cinsiyet (İsteğe Bağlı)',
                              prefixIcon: const Icon(Icons.male),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: ['Erkek', 'Dişi'].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _gender = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kısır mı?', style: TextStyle(fontSize: 13)),
                                Switch(
                                  value: _isNeutered,
                                  activeColor: AppTheme.primaryColor,
                                  onChanged: (val) {
                                    setState(() => _isNeutered = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _microchipController,
                      decoration: InputDecoration(
                        labelText: 'Mikroçip Numarası (İsteğe Bağlı)',
                        hintText: 'örn: 900123456789012',
                        prefixIcon: const Icon(Icons.qr_code),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _allergiesController,
                      decoration: InputDecoration(
                        labelText: 'Alerji & Sağlık Notları (İsteğe Bağlı)',
                        hintText: 'örn: Tavuk etine alerjisi var, kronik rahatsızlığı yok',
                        prefixIcon: const Icon(Icons.medical_information),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Ek Notlar & Aşı Bilgisi (İsteğe Bağlı)',
                        hintText: 'örn: Karma aşısı 15 Haziran\'da yapıldı',
                        prefixIcon: const Icon(Icons.note_alt),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleSavePet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Evcil Hayvanı Kaydet',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
