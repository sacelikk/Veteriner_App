class UserModel {
  final String id;
  final String email;
  final String role; // "Pet Sahibi", "Veteriner Hekim" veya "Misafir"
  final String name;
  final bool isGuest;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
    this.isGuest = false,
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

