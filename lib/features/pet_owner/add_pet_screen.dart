import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../services/fake_database.dart';
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
  final TextEditingController _typeController = TextEditingController(text: 'Köpek');
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _ageController.dispose();
    _weightController.dispose();
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
      final newPet = PetModel(
        id: Random().nextInt(10000).toString(),
        ownerId: currentUser.id,
        name: _nameController.text.trim(),
        type: _typeController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 1,
        weight: double.tryParse(_weightController.text.trim()) ?? 1.0,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Evcil Hayvan Ekle'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Petinizin Adı',
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              initialValue: _typeController.text,
              decoration: InputDecoration(
                labelText: 'Türü',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Kedi', 'Köpek', 'Kuş', 'Diğer'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) _typeController.text = newValue;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Yaş',
                      prefixIcon: const Icon(Icons.cake),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _weightController,
                    decoration: InputDecoration(
                      labelText: 'Kilo (kg)',
                      prefixIcon: const Icon(Icons.monitor_weight),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _isLoading ? null : _handleSavePet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}