import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/pet_model.dart';
import '../../models/vaccine_model.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import 'package:uuid/uuid.dart';

class PetDetailsScreen extends ConsumerStatefulWidget {
  final PetModel pet;
  const PetDetailsScreen({super.key, required this.pet});

  @override
  ConsumerState<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends ConsumerState<PetDetailsScreen> {
  
  void _showAddVaccineSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddVaccineSheet(pet: widget.pet),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.pet.name} - Sağlık Kaydı'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVaccineSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Aşı / Kontrol Ekle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pet Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryLight,
                      child: widget.pet.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                widget.pet.photoUrl!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Icon(
                              widget.pet.type.toLowerCase() == 'kedi'
                                  ? Icons.pets
                                  : Icons.pets,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.pet.name,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text('${widget.pet.type} • ${widget.pet.age} Yaşında • ${widget.pet.weight} kg'),
                          if (widget.pet.breed != null) Text('Irk: ${widget.pet.breed}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Aşı ve Kontrol Geçmişi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 12),
            
            // Vaccine List
            Consumer(
              builder: (context, ref, child) {
                final vaccinesAsync = ref.watch(petVaccinesProvider(widget.pet.id));
                
                return vaccinesAsync.when(
                  data: (vaccines) {
                    if (vaccines.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Text(
                              'Henüz hiç aşı veya kontrol kaydı eklenmemiş.',
                              style: TextStyle(color: AppTheme.textLight),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    // Sort descending for display (newest first)
                    final sortedVaccines = List<VaccineModel>.from(vaccines)
                      ..sort((a, b) => b.dateAdministered.compareTo(a.dateAdministered));
                      
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedVaccines.length,
                      itemBuilder: (context, index) {
                        final v = sortedVaccines[index];
                        final isUpcoming = v.nextDueDate.isAfter(DateTime.now());
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isUpcoming ? Colors.orange.shade100 : Colors.green.shade100,
                              child: Icon(
                                Icons.vaccines,
                                color: isUpcoming ? Colors.orange.shade800 : Colors.green.shade800,
                              ),
                            ),
                            title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('Yapıldığı Tarih: ${DateFormat('dd.MM.yyyy').format(v.dateAdministered)}'),
                                Text(
                                  'Sonraki Kontrol: ${DateFormat('dd.MM.yyyy').format(v.nextDueDate)}',
                                  style: TextStyle(
                                    color: isUpcoming ? Colors.orange.shade800 : AppTheme.textLight,
                                    fontWeight: isUpcoming ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                if (v.notes != null) ...[
                                  const SizedBox(height: 4),
                                  Text('Not: ${v.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ]
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Hata: $e')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddVaccineSheet extends ConsumerStatefulWidget {
  final PetModel pet;
  const _AddVaccineSheet({required this.pet});

  @override
  ConsumerState<_AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends ConsumerState<_AddVaccineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _dateAdministered = DateTime.now();
  DateTime? _nextDueDate = DateTime.now().add(const Duration(days: 365)); // Default 1 year
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context, bool isAdministered) async {
    final initialDate = isAdministered ? (_dateAdministered ?? DateTime.now()) : (_nextDueDate ?? DateTime.now().add(const Duration(days: 365)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isAdministered) {
          _dateAdministered = picked;
          // Otomatik olarak sonraki aşıyı 1 yıl sonraya ayarla
          _nextDueDate = DateTime(picked.year + 1, picked.month, picked.day);
        } else {
          _nextDueDate = picked;
        }
      });
    }
  }

  Future<void> _saveVaccine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateAdministered == null || _nextDueDate == null) return;

    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      final vaccine = VaccineModel(
        id: const Uuid().v4(),
        ownerId: widget.pet.ownerId,
        petId: widget.pet.id,
        name: _nameController.text.trim(),
        dateAdministered: _dateAdministered!,
        nextDueDate: _nextDueDate!,
        notes: _notesController.text.trim(),
      );
      
      await db.addVaccine(vaccine);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
        left: 24,
        right: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yeni Aşı / Kontrol Ekle',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Aşı / Uygulama Adı',
                hintText: 'Örn: Kuduz Aşısı, İç Dış Parazit',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Lütfen bir isim girin' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Yapıldığı Tarih', border: OutlineInputBorder()),
                      child: Text(_dateAdministered == null ? 'Seçiniz' : DateFormat('dd.MM.yyyy').format(_dateAdministered!)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Sonraki Kontrol', border: OutlineInputBorder()),
                      child: Text(_nextDueDate == null ? 'Seçiniz' : DateFormat('dd.MM.yyyy').format(_nextDueDate!)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notlar (İsteğe bağlı)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveVaccine,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}
