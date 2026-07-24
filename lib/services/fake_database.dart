import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';

// Ana veritabanı servisini FirebaseService olarak ayarlıyoruz
final databaseProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

// Pet listesini Firebase'den anlık dinlemek için StreamProvider
final myPetsProvider = StreamProvider<List<PetModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMyPetsStream();
});

// Sohbet mesajlarını Firebase'den anlık dinlemek için StreamProvider
// Şimdilik test amaçlı sabit bir chatId kullanıyoruz ('test_chat_room')
final chatProvider = StreamProvider<List<MessageModel>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.getMessagesStream('test_chat_room');
});

