import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_service.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/vet_review_model.dart';
import '../models/vaccine_model.dart';
import '../models/adoption_model.dart';
import '../models/chat_thread_model.dart';
// Ana veritabanı servisini FirebaseService olarak ayarlıyoruz
final databaseProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Pet listesini Firebase'den anlık dinlemek için StreamProvider
final myPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMyPetsStream();
});

// Veteriner Hekimleri getiren StreamProvider (Anlık güncellemeler için)
final veterinariansProvider = StreamProvider<List<UserModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getVeterinariansStream();
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
// Aşı ve Kontrol Tarihleri İçin Sağlayıcılar
final upcomingVaccinesProvider = StreamProvider<List<VaccineModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMyUpcomingVaccinesStream();
});

final petVaccinesProvider = StreamProvider.family<List<VaccineModel>, String>((ref, petId) {
  final db = ref.watch(databaseProvider);
  return db.getVaccinesStream(petId);
});

// Sahiplendirme İlanlarını dinleyen StreamProvider
final adoptionsProvider = StreamProvider<List<AdoptionModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getAdoptionsStream();
});
// Kullanıcının Sahiplendirme Mesaj Kutusu (Inbox)
final userChatsProvider = StreamProvider<List<ChatThreadModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getUserChatsStream();
});

// Belirli bir Sahiplendirme Chat'indeki Mesajlar
final adoptionChatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final db = ref.watch(databaseProvider);
  return db.getAdoptionMessagesStream(chatId);
});

// Belirli bir ChatThreadModel verisini dinleyen StreamProvider
final chatThreadProvider = StreamProvider.family<ChatThreadModel?, String>((ref, chatId) {
  final db = ref.watch(databaseProvider);
  return FirebaseFirestore.instance.collection('chat_threads').doc(chatId).snapshots().map((doc) {
    if (doc.exists) {
      return ChatThreadModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  });
});
