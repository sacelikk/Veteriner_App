import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/vet_review_model.dart';

// Ana veritabanı servisini FirebaseService olarak ayarlıyoruz
final databaseProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Pet listesini Firebase'den anlık dinlemek için StreamProvider
final myPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMyPetsStream();
});

// Veteriner Hekimleri getiren FutureProvider
final veterinariansProvider = FutureProvider<List<UserModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getVeterinarians();
});

// Veteriner Hekim Değerlendirmelerini dinleyen StreamProvider.family
final vetReviewsProvider = StreamProvider.family<List<VetReviewModel>, String>((ref, vetId) {
  final db = ref.watch(databaseProvider);
  return db.getVetReviewsStream(vetId);
});

// Sohbet mesajlarını dinamik chatId ile dinlemek için StreamProvider.family
final chatProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final db = ref.watch(databaseProvider);
  return db.getMessagesStream(chatId);
});

// Veteriner hekimin bekleyen talepleri dinlemesi için StreamProvider
final pendingRequestsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getPendingSupportRequestsStream();
});

// Pet sahibinin kendi talebinin durumunu dinlemesi için StreamProvider.family
final supportRequestStatusProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, requestId) {
  final db = ref.watch(databaseProvider);
  return db.getSupportRequestStatusStream(requestId);
});



