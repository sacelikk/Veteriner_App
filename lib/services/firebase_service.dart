import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';
import '../models/vet_review_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? currentUser;

  // Kayıt Olma (E-posta ve Şifre)
  Future<void> registerWithEmail(String email, String password, String name, String role) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      String uid = userCred.user!.uid;

      // Firestore'a kullanıcı detaylarını kaydet
      await _firestore.collection('users').doc(uid).set({
        'email': email,
        'name': name,
        'role': role,
      });

      currentUser = UserModel(
        id: uid,
        email: email,
        role: role,
        name: name,
      );
    } catch (e) {
      throw Exception("Kayıt Hatası: $e");
    }
  }

  // Misafir Girişi
  void loginAsGuest() {
    currentUser = UserModel.guest();
  }

  // Giriş Yapma (E-posta ve Şifre)
  Future<void> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      String uid = userCred.user!.uid;

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentUser = UserModel(
          id: uid,
          email: data['email'] ?? email,
          role: data['role'] ?? 'Pet Sahibi',
          name: data['name'] ?? 'Kullanıcı',
          clinicName: data['clinicName'],
          workingDaysHours: data['workingDaysHours'],
          phone: data['phone'],
          address: data['address'],
          bio: data['bio'],
          specialties: data['specialties'] != null ? List<String>.from(data['specialties']) : [],
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          isOnline: data['isOnline'] ?? false,
        );
      } else {
        currentUser = UserModel(
          id: uid,
          email: userCred.user?.email ?? email,
          role: 'Pet Sahibi',
          name: userCred.user?.displayName ?? email.split('@').first,
        );
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '');
      if (msg.contains('invalid-credential') || msg.contains('wrong-password') || msg.contains('user-not-found')) {
        throw Exception("E-posta adresi veya şifre hatalı.");
      }
      throw Exception(msg);
    }
  }

  // Oturumu Kapat
  Future<void> logout() async {
    if (_auth.currentUser != null) {
      await _auth.signOut();
    }
    currentUser = null;
  }

  // Aktif Oturumu Kontrol Etme (Uygulama açılışında çalışacak)
  Future<UserModel?> checkCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      try {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          currentUser = UserModel(
            id: firebaseUser.uid,
            email: data['email'] ?? firebaseUser.email!,
            role: data['role'] ?? 'Pet Sahibi',
            name: data['name'] ?? 'İsimsiz',
            clinicName: data['clinicName'],
            workingDaysHours: data['workingDaysHours'],
            phone: data['phone'],
            address: data['address'],
            bio: data['bio'],
            specialties: data['specialties'] != null ? List<String>.from(data['specialties']) : [],
            rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
            reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
            isOnline: data['isOnline'] ?? false,
          );
          return currentUser;
        }
      } catch (_) {}
      
      currentUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        role: 'Pet Sahibi',
        name: firebaseUser.displayName ?? 'Kullanıcı',
      );
      return currentUser;
    }
    return null;
  }

  // Veteriner Hekimleri Getirme (Misafir ve Pet Sahibi Görünümü İçin)
  Future<List<UserModel>> getVeterinarians() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Veteriner Hekim')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3));

      List<UserModel> vets = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel(
          id: doc.id,
          email: data['email'] ?? '',
          role: data['role'] ?? 'Veteriner Hekim',
          name: data['name'] ?? 'Veteriner Hekim',
          clinicName: data['clinicName'],
          workingDaysHours: data['workingDaysHours'],
          phone: data['phone'],
          address: data['address'],
          bio: data['bio'],
          specialties: data['specialties'] != null 
              ? List<String>.from(data['specialties']) 
              : [],
          rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
          reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
          isOnline: data['isOnline'] ?? false,
        );
      }).toList();

      return vets;
    } catch (_) {
      return [];
    }
  }

  // Değerlendirme & Yorum Ekleme
  Future<void> addVetReview(String vetId, double rating, String comment) async {
    final reviewerName = currentUser?.name ?? 'Anonim Pet Sahibi';
    await _firestore.collection('vet_reviews').add({
      'vetId': vetId,
      'reviewerName': reviewerName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Değerlendirmeleri Dinleme (Stream)
  Stream<List<VetReviewModel>> getVetReviewsStream(String vetId) {
    return _firestore
        .collection('vet_reviews')
        .where('vetId', isEqualTo: vetId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return VetReviewModel.fromMap(doc.id, doc.data());
      }).toList();
    }).handleError((_) => <VetReviewModel>[]);
  }

  // Pet Ekleme
  Future<void> addPet(PetModel pet) async {
    if (currentUser == null) return;
    await _firestore.collection('pets').doc(pet.id).set(pet.toMap());
  }

  // Kullanıcının Petlerini Getirme (Future)
  Future<List<PetModel>> getMyPets() async {
    if (currentUser == null) return [];
    final snapshot = await _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: currentUser!.id)
        .get();

    return snapshot.docs.map((doc) => PetModel.fromMap(doc.id, doc.data())).toList();
  }

  // Kullanıcının Petlerini Dinleme (Stream)
  Stream<List<PetModel>> getMyPetsStream() {
    if (currentUser == null) return Stream.value([]);
    return _firestore
        .collection('pets')
        .where('ownerId', isEqualTo: currentUser!.id)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PetModel.fromMap(doc.id, doc.data())).toList();
    });
  }

  // Mesaj Gönderme
  Future<void> sendMessage(String text, String chatId) async {
    if (currentUser == null) return;
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Görüntülü Görüşme Daveti Gönderme
  Future<void> sendCallInvite(String chatId) async {
    if (currentUser == null) return;
    await _firestore.collection('chats').doc(chatId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': '📹 Görüntülü görüşme daveti gönderildi. Katılmak için dokunun.',
      'type': 'call_invite',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Mesajları Dinleme (Stream)
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.id, doc.data());
      }).toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    }).handleError((_) => <MessageModel>[]);
  }

  // Canlı Destek Talebi Oluşturma (Pet Sahibi)
  Future<String> createSupportRequest(String problemDescription) async {
    if (currentUser == null) throw Exception("Oturum açık değil.");
    
    // Yeni bir chat odası ID'si ve talep ID'si oluştur (Firestore otomatik ID kullanabiliriz)
    final docRef = _firestore.collection('support_requests').doc();
    final chatId = docRef.id; // Talep ID'sini aynı zamanda sohbet odası ID'si olarak kullanalım

    await docRef.set({
      'petOwnerId': currentUser!.id,
      'petOwnerName': currentUser!.name,
      'problemDescription': problemDescription,
      'status': 'pending', // pending, accepted, completed
      'createdAt': FieldValue.serverTimestamp(),
      'chatId': chatId,
      'vetId': null,
      'vetName': null,
    });
    
    return chatId;
  }

  // Bekleyen Talepleri Dinleme (Veteriner Hekim için)
  Stream<List<Map<String, dynamic>>> getPendingSupportRequestsStream() {
    return _firestore
        .collection('support_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      list.sort((a, b) {
        final tA = a['createdAt'] as Timestamp?;
        final tB = b['createdAt'] as Timestamp?;
        if (tA == null && tB == null) return 0;
        if (tA == null) return -1;
        if (tB == null) return 1;
        return tB.compareTo(tA);
      });
      return list;
    }).handleError((_) => <Map<String, dynamic>>[]);
  }

  // Talebi Kabul Etme (Veteriner Hekim)
  Future<String> acceptSupportRequest(String requestId) async {
    if (currentUser == null) throw Exception("Oturum açık değil.");
    
    final docRef = _firestore.collection('support_requests').doc(requestId);
    
    // Talebin durumunu güncelle
    await docRef.update({
      'status': 'accepted',
      'vetId': currentUser!.id,
      'vetName': currentUser!.name,
    });
    
    // Sohbet odasına ilk karşılama mesajını otomatik atalım
    await _firestore.collection('chats').doc(requestId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': 'Merhaba, ben ${currentUser!.name}. Şikayetinizi inceledim, nasıl yardımcı olabilirim?',
      'timestamp': FieldValue.serverTimestamp(),
    });

    return requestId; // chatId ile requestId aynı
  }

  // Talep Durumunu Dinleme (Pet Sahibi için - Veteriner kabul etti mi diye kontrol eder)
  Stream<Map<String, dynamic>?> getSupportRequestStatusStream(String requestId) {
    return _firestore.collection('support_requests').doc(requestId).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }
}
