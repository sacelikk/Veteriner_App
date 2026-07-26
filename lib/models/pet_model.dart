class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String type; // Kedi, Köpek vs.
  final int age;
  final double weight;
  final String? breed; // Irk / Cins (ör. British Shorthair, Golden Retriever)
  final String? gender; // Erkek / Dişi
  final bool? isNeutered; // Kısırlaştırılmış mı
  final String? microchipNo; // Mikroçip Numarası
  final String? allergies; // Alerjiler / Sağlık Notları
  final String? notes; // Ek notlar / Aşı Bilgileri
  final String? photoUrl; // Profil Fotoğrafı (URL veya seçilen görsel/avatar)

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.age,
    required this.weight,
    this.breed,
    this.gender,
    this.isNeutered,
    this.microchipNo,
    this.allergies,
    this.notes,
    this.photoUrl,
  });

  factory PetModel.fromMap(String id, Map<String, dynamic> data) {
    return PetModel(
      id: id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      type: data['type'] ?? 'Kedi',
      age: (data['age'] as num?)?.toInt() ?? 1,
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
      breed: data['breed'],
      gender: data['gender'],
      isNeutered: data['isNeutered'],
      microchipNo: data['microchipNo'],
      allergies: data['allergies'],
      notes: data['notes'],
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'type': type,
      'age': age,
      'weight': weight,
      if (breed != null && breed!.isNotEmpty) 'breed': breed,
      if (gender != null && gender!.isNotEmpty) 'gender': gender,
      if (isNeutered != null) 'isNeutered': isNeutered,
      if (microchipNo != null && microchipNo!.isNotEmpty) 'microchipNo': microchipNo,
      if (allergies != null && allergies!.isNotEmpty) 'allergies': allergies,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (photoUrl != null && photoUrl!.isNotEmpty) 'photoUrl': photoUrl,
    };
  }
}
