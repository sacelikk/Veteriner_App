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
}

