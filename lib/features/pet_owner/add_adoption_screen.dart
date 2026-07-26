import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../models/adoption_model.dart';
import '../../theme/animated_dialog.dart';

class AddAdoptionScreen extends ConsumerStatefulWidget {
  const AddAdoptionScreen({super.key});

  @override
  ConsumerState<AddAdoptionScreen> createState() => _AddAdoptionScreenState();
}

class _AddAdoptionScreenState extends ConsumerState<AddAdoptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ageController = TextEditingController();
  final _locationController = TextEditingController();
  final _photoUrlController = TextEditingController();

  String _selectedSpecies = 'Kedi';
  bool _isLoading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  final List<String> _speciesOptions = ['Kedi', 'Köpek', 'Kuş', 'Tavşan', 'Diğer'];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final db = ref.read(databaseProvider);
      final currentUser = db.currentUser;
      if (currentUser == null) throw Exception("Kullanıcı bulunamadı.");

      String? uploadedUrl;
      if (_selectedImage != null) {
        final imagePath = 'adoptions/${const Uuid().v4()}.jpg';
        uploadedUrl = await db.uploadImageToStorage(_selectedImage!, imagePath);
      }

      final adoption = AdoptionModel(
        id: const Uuid().v4(),
        ownerId: currentUser.id,
        ownerName: currentUser.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        species: _selectedSpecies,
        age: _ageController.text.trim(),
        location: _locationController.text.trim(),
        photoUrl: uploadedUrl,
        createdAt: Timestamp.now(),
      );

      await db.addAdoptionListing(adoption);

      if (mounted) {
        AnimatedDialog.show(
          context,
          title: 'İlan Eklendi',
          message: 'Sahiplendirme ilanı başarıyla yayınlandı.',
          type: DialogType.success,
          onConfirm: () {
            Navigator.pop(context); // Sayfayı kapat
          },
        );
      }
    } catch (e) {
      if (mounted) {
        AnimatedDialog.show(
          context,
          title: 'Hata',
          message: 'İlan eklenirken bir hata oluştu: $e',
          type: DialogType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Yeni İlan Ver'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Yeni Yuva Arıyoruz 🐾',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Lütfen sahiplendirmek istediğiniz dostumuz hakkında gerekli bilgileri eksiksiz doldurun.',
                style: TextStyle(fontSize: 14, color: AppTheme.textLight),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Başlık
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'İlan Başlığı',
                  hintText: 'Örn: 2 Aylık Sevimli Tekir',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Tür Seçimi
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                decoration: InputDecoration(
                  labelText: 'Türü',
                  prefixIcon: const Icon(Icons.pets),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _speciesOptions.map((String species) {
                  return DropdownMenuItem<String>(
                    value: species,
                    child: Text(species),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedSpecies = newValue);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Yaş
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Yaşı',
                  hintText: 'Örn: 3 Aylık, 2 Yaşında',
                  prefixIcon: const Icon(Icons.cake),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Yaş gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Konum
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Bulunduğu Şehir/İlçe',
                  hintText: 'Örn: Kadıköy, İstanbul',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Konum gerekli' : null,
              ),
              const SizedBox(height: 16),

              // Fotoğraf Yükleme Alanı
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400, width: 1, style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: AppTheme.primaryColor.withOpacity(0.6)),
                            const SizedBox(height: 8),
                            const Text(
                              'Galeriden Fotoğraf Seç (İsteğe Bağlı)',
                              style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Açıklama
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Açıklama (Karakteri, Sağlık Durumu vs.)',
                  hintText: 'Hayvan hakkında detaylı bilgi verin...',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                ),
                validator: (val) => val == null || val.isEmpty ? 'Açıklama gerekli' : null,
              ),
              const SizedBox(height: 32),

              // Kaydet Butonu
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'İlanı Yayınla',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
