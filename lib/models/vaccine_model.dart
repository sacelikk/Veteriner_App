import 'package:cloud_firestore/cloud_firestore.dart';

class VaccineModel {
  final String id;
  final String ownerId;
  final String petId;
  final String name; // Aşı/Kontrol Adı (Örn: Kuduz, İç Parazit)
  final DateTime dateAdministered; // Yapıldığı Tarih
  final DateTime nextDueDate; // Bir Sonraki Kontrol/Aşı Tarihi
  final String? notes; // Ek Notlar

  VaccineModel({
    required this.id,
    required this.ownerId,
    required this.petId,
    required this.name,
    required this.dateAdministered,
    required this.nextDueDate,
    this.notes,
  });

  factory VaccineModel.fromMap(String id, Map<String, dynamic> data) {
    return VaccineModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      petId: data['petId'] ?? '',
      name: data['name'] ?? '',
      dateAdministered: (data['dateAdministered'] as Timestamp).toDate(),
      nextDueDate: (data['nextDueDate'] as Timestamp).toDate(),
      notes: data['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'petId': petId,
      'name': name,
      'dateAdministered': Timestamp.fromDate(dateAdministered),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
    };
  }
}
