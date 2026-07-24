class UserModel {
  final String id;
  final String email;
  final String role; // "Pet Sahibi" veya "Veteriner Hekim"
  final String name;

  UserModel({
    required this.id,
    required this.email,
    required this.role,
    required this.name,
  });
}
