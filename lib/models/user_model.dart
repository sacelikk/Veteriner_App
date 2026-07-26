class UserModel {
  final String id;
  final String email;
  final String role; // "Pet Sahibi", "Veteriner Hekim" veya "Misafir"
  final String name;
  final bool isGuest;
  final String? clinicName;
  final String? workingDaysHours;
  final String? phone;
  final String? address;
  final String? bio;
  final List<String>? specialties;
  final double rating;
  final int reviewCount;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.isGuest = false,
    this.clinicName,
    this.workingDaysHours,
    this.phone,
    this.address,
    this.bio,
    this.specialties,
    this.rating = 5.0,
    this.reviewCount = 1,
    this.isOnline = true,
  });

  factory UserModel.guest() {
    return UserModel(
      id: 'guest_user',
      email: '',
      role: 'Misafir',
      name: 'Misafir Kullanıcı',
      isGuest: true,
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? role,
    String? name,
    bool? isGuest,
    String? clinicName,
    String? workingDaysHours,
    String? phone,
    String? address,
    String? bio,
    List<String>? specialties,
    double? rating,
    int? reviewCount,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      isGuest: isGuest ?? this.isGuest,
      clinicName: clinicName ?? this.clinicName,
      workingDaysHours: workingDaysHours ?? this.workingDaysHours,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      specialties: specialties ?? this.specialties,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

