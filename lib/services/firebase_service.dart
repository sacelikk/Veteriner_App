import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? currentUser;

  // Giriş Yapma veya Kayıt Olma
  Future<void> login(String email, String role) async {
    // Gerçekte şifre de alınmalı, prototip için sadece e-posta ile giriş simülasyonu yapıyoruz
    // Firestore'dan kullanıcıyı bul, yoksa oluştur
    try {
      // Şimdilik Anonim giriş yapıp veritabanına kaydedelim (Hızlı test için)
      UserCredential userCred = await _auth.signInAnonymously();
      String uid = userCred.user!.uid;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        // Yeni kullanıcı oluştur
        await _firestore.collection('users').doc(uid).set({
          'email': email,
          'role': role,
          'name': role == 'Pet Sahibi' ? 'Ahmet Yılmaz' : 'Vet. Dr. Ayşe',
        });
      }

      currentUser = UserModel(
        id: uid,
        email: email,
        role: role,
        name: role == 'Pet Sahibi' ? 'Ahmet Yılmaz' : 'Vet. Dr. Ayşe',
      );
    } catch (e) {
      print("Firebase Login Hatası: $e");
    }
  }

  // Pet Ekleme
  Future<void> addPet(PetModel pet) async {
    if (currentUser == null) return;
    await _firestore.collection('pets').doc(pet.id).set({
      'ownerId': currentUser!.id,
      'name': pet.name,
      'type': pet.type,
      'age': pet.age,
      'weight': pet.weight,
    });
  }

  // Kullanıcının Petlerini Getirme (Future)
  Future<List<PetModel>> getMyPets() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: currentUser!.id)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return PetModel(
        id: doc.id,
        ownerId: data['ownerId'],
        name: data['name'],
        type: data['type'],
        age: data['age'],
        weight: (data['weight'] as num).toDouble(),
      );
    }).toList();
  }

  // Kullanıcının Petlerini Dinleme (Stream)
  Stream<List<PetModel>> getMyPetsStream() {
    if (currentUser == null) return Stream.value([]);
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: currentUser!.id)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PetModel(
          id: doc.id,
          ownerId: data['ownerId'],
          name: data['name'],
          type: data['type'],
          age: data['age'],
          weight: (data['weight'] as num).toDouble(),
        );
      }).toList();
    });
  }

  // Mesaj Gönderme
  Future<void> sendMessage(String text, String chatId) async {
    if (currentUser == null) return;
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mesajları Dinleme (Stream)
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MessageModel(
          id: doc.id,
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }
}
