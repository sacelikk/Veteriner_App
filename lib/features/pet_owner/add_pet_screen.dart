import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../services/fake_database.dart';
import '../../models/pet_model.dart';

class AddPetScreen extends ConsumerWidget {
  const AddPetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controllerlar (Formdaki verileri almak için)
    final nameController = TextEditingController();
    final typeController = TextEditingController(text: 'Köpek'); // Varsayılan değer
    final ageController = TextEditingController();
    final weightController = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Yeni Evcil Hayvan Ekle'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // İsim Alanı
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Petinizin Adı',
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Tür Alanı (Kedi, Köpek vs.)
            DropdownButtonFormField<String>(
              initialValue: typeController.text,
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
                if (newValue != null) typeController.text = newValue;
              },
            ),
            const SizedBox(height: 16),

            // Yaş ve Kilo yan yana
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ageController,
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
                    controller: weightController,
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

            // Kaydet Butonu
            ElevatedButton(
              onPressed: () async {
                // Basit Doğrulama
                if (nameController.text.isEmpty || ageController.text.isEmpty || weightController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
                  );
                  return;
                }

                // Yükleniyor Uyarısı
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pet kaydediliyor...')),
                );

                final db = ref.read(databaseProvider);
                final currentUser = db.currentUser;
                
                if (currentUser == null) return;

                final newPet = PetModel(
                  id: Random().nextInt(1000).toString(),
                  ownerId: currentUser.id,
                  name: nameController.text,
                  type: typeController.text,
                  age: int.tryParse(ageController.text) ?? 1,
                  weight: double.tryParse(weightController.text) ?? 1.0,
                );

                await db.addPet(newPet);
                ref.invalidate(myPetsProvider); // Ana sayfadaki listeyi yenilemesini söyler

                if (!context.mounted) return;
                Navigator.pop(context); // Önceki sayfaya dön
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
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