import 'package:cloud_firestore/cloud_firestore.dart';

class AdoptionModel {
  final String id;
  final String ownerId; // İlanı açan kişinin ID'si
  final String ownerName; // İlanı açan kişinin Adı
  final String title;
  final String description;
  final String species; // Türü (Kedi, Köpek vb)
  final String age; // Yaşı (1 aylık, 2 yaşında vb)
  final String location; // Şehir / İlçe
  final String? photoUrl; // Opsiyonel resim linki
  final Timestamp createdAt;
  final String status; // 'active', 'adopted'

  AdoptionModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.description,
    required this.species,
    required this.age,
    required this.location,
    this.photoUrl,
    required this.createdAt,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'description': description,
      'species': species,
      'age': age,
      'location': location,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
      'status': status,
    };
  }

  factory AdoptionModel.fromMap(String id, Map<String, dynamic> map) {
    return AdoptionModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      ownerName: map['ownerName'] ?? 'Bilinmeyen Kullanıcı',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      species: map['species'] ?? '',
      age: map['age'] ?? '',
      location: map['location'] ?? '',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] ?? Timestamp.now(),
      status: map['status'] ?? 'active',
    );
  }
}
