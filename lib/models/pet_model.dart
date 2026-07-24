class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String type; // Kedi, Köpek vs.
  final int age;
  final double weight;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.age,
    required this.weight,
  });
}
