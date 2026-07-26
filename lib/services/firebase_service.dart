import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';
import '../models/vet_review_model.dart';
import '../models/vaccine_model.dart';
import '../models/adoption_model.dart';
import '../models/chat_thread_model.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

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
        'isOnline': true,
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
        await _firestore.collection('users').doc(uid).update({'isOnline': true});
        final data = doc.data() as Map<String, dynamic>;
        data['isOnline'] = true;
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
      String uid = _auth.currentUser!.uid;
      try {
        await _firestore.collection('users').doc(uid).update({'isOnline': false});
      } catch (_) {}
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
          await _firestore.collection('users').doc(firebaseUser.uid).update({'isOnline': true});
          final data = doc.data() as Map<String, dynamic>;
          data['isOnline'] = true;
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

  // Çevrimiçi/Çevrimdışı Durumunu Güncelleme (Manuel Toggle)
  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      try {
        await _firestore.collection('users').doc(uid).update({'isOnline': isOnline});
        if (currentUser != null) {
          currentUser = currentUser!.copyWith(isOnline: isOnline);
        }
      } catch (_) {}
    }
  }

  // Profil Güncelleme (Veteriner Hekim için)
  Future<void> updateVetProfile({
    required String name,
    required String clinicName,
    required String workingDaysHours,
    required String phone,
    required String address,
    required String bio,
  }) async {
    if (_auth.currentUser != null) {
      String uid = _auth.currentUser!.uid;
      try {
        await _firestore.collection('users').doc(uid).update({
          'name': name,
          'clinicName': clinicName,
          'workingDaysHours': workingDaysHours,
          'phone': phone,
          'address': address,
          'bio': bio,
        });

        // Update local user model
        if (currentUser != null) {
          currentUser = currentUser!.copyWith(
            name: name,
            clinicName: clinicName,
            workingDaysHours: workingDaysHours,
            phone: phone,
            address: address,
            bio: bio,
          );
        }
      } catch (e) {
        throw Exception("Profil güncellenemedi: $e");
      }
    }
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

  // Veteriner Hekimleri Dinleme (Stream)
  Stream<List<UserModel>> getVeterinariansStream() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'Veteriner Hekim')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
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
    }).handleError((_) => <UserModel>[]);
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
    await _firestore.collection('chat_threads').doc(chatId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': text,
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chat_threads').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Görüntülü Görüşme Daveti Gönderme
  Future<void> sendCallInvite(String chatId) async {
    if (currentUser == null) return;
    final text = '📹 Görüntülü görüşme daveti gönderildi. Katılmak için dokunun.';
    await _firestore.collection('chat_threads').doc(chatId).collection('messages').add({
      'senderId': currentUser!.id,
      'text': text,
      'type': 'call_invite',
      'timestamp': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('chat_threads').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  // Mesajları Dinleme (Stream)
  Stream<List<MessageModel>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chat_threads')
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

  // Aşı/Kontrol Ekleme
  Future<void> addVaccine(VaccineModel vaccine) async {
    if (currentUser == null) return;
    await _firestore.collection('vaccines').doc(vaccine.id).set(vaccine.toMap());
  }

  // Belirli Bir Petin Aşılarını Dinleme
  Stream<List<VaccineModel>> getVaccinesStream(String petId) {
    return _firestore
        .collection('vaccines')
        .where('petId', isEqualTo: petId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => VaccineModel.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => a.dateAdministered.compareTo(b.dateAdministered));
      return list;
    }).handleError((_) => <VaccineModel>[]);
  }

  // Yaklaşan Aşıları Dinleme (Pet Sahibi İçin)
  Stream<List<VaccineModel>> getMyUpcomingVaccinesStream() {
    if (currentUser == null) return Stream.value([]);
    
    // Yalnızca gelecekteki aşıları/kontrolleri getir
    final now = DateTime.now();
    
    return _firestore
        .collection('vaccines')
        .where('ownerId', isEqualTo: currentUser!.id)
        .where('nextDueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime(now.year, now.month, now.day)))
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => VaccineModel.fromMap(doc.id, doc.data())).toList();
      // Tarihe göre yakın olanlar en üstte
      list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return list;
    }).handleError((_) => <VaccineModel>[]);
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

  // Veteriner Puanlama İşlemi
  Future<void> submitVetRating(String vetId, int newRating) async {
    final vetDoc = _firestore.collection('users').doc(vetId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(vetDoc);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      final double currentRating = (data['rating'] as num?)?.toDouble() ?? 0.0;
      final int reviewCount = (data['reviewCount'] as num?)?.toInt() ?? 0;
      
      final int newReviewCount = reviewCount + 1;
      final double newAverage = ((currentRating * reviewCount) + newRating) / newReviewCount;
      
      transaction.update(vetDoc, {
        'rating': newAverage,
        'reviewCount': newReviewCount,
      });
    });
  }

  // Arama Reddetme
  Future<void> rejectCall(String chatId, String messageId) async {
    await _firestore
        .collection('chat_threads')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'type': 'call_rejected',
      'text': 'Görüntülü görüşme çağrısı reddedildi.',
    });
  }

  // Talebi Kabul Etme (Veteriner Hekim)
  Future<String> acceptSupportRequest(String requestId) async {
    if (currentUser == null) throw Exception("Oturum açık değil.");
    
    final docRef = _firestore.collection('support_requests').doc(requestId);
    final docSnapshot = await docRef.get();
    
    // Talebin durumunu güncelle
    await docRef.update({
      'status': 'accepted',
      'vetId': currentUser!.id,
      'vetName': currentUser!.name,
    });
    
    // ChatThreadModel oluştur
    final petOwnerId = docSnapshot.data()?['petOwnerId'] ?? '';
    final petOwnerName = docSnapshot.data()?['petOwnerName'] ?? 'Pet Sahibi';
    
    final thread = ChatThreadModel(
      id: requestId,
      participants: [currentUser!.id, petOwnerId],
      participantNames: {
        currentUser!.id: currentUser!.name,
        petOwnerId: petOwnerName,
      },
      lastMessage: 'Merhaba, ben ${currentUser!.name}. Şikayetinizi inceledim, nasıl yardımcı olabilirim?',
      lastMessageTime: DateTime.now(),
      chatType: 'vet_support',
      status: 'active',
    );
    
    await _firestore.collection('chat_threads').doc(requestId).set(thread.toMap());

    // Sohbet odasına ilk karşılama mesajını otomatik atalım
    final msgId = const Uuid().v4();
    await _firestore.collection('chat_threads').doc(requestId).collection('messages').doc(msgId).set({
      'senderId': currentUser!.id,
      'text': thread.lastMessage,
      'type': 'text',
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
  // Sahiplendirme İlanı Ekleme
  Future<void> addAdoptionListing(AdoptionModel adoption) async {
    if (currentUser == null) throw Exception("Oturum açık değil.");
    await _firestore.collection('adoptions').doc(adoption.id).set(adoption.toMap());
  }

  // Fotoğrafı Firebase Storage'a yükleme ve indirme URL'ini alma
  Future<String?> uploadImageToStorage(File imageFile, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Resim yükleme hatası: $e");
      return null;
    }
  }

  // Tüm Aktif Sahiplendirme İlanlarını Dinleme
  Stream<List<AdoptionModel>> getAdoptionsStream() {
    return _firestore
        .collection('adoptions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => AdoptionModel.fromMap(doc.id, doc.data())).toList();
      // En yeniler en üstte
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <AdoptionModel>[]);
  }

  // -------------------------
  // User-to-User Adoption Chat & Universal Chat logic
  // -------------------------

  Future<void> closeChat(String chatId) async {
    if (currentUser == null) return;
    await _firestore.collection('chat_threads').doc(chatId).update({
      'status': 'closed',
    });
  }

  Future<String> createOrGetAdoptionChat({
    required String peerId,
    required String peerName,
    required String adoptionId,
    required String adoptionTitle,
  }) async {
    if (currentUser == null) throw Exception("Oturum açık değil.");
    
    // Check if chat already exists
    final querySnapshot = await _firestore
        .collection('chat_threads')
        .where('adoptionId', isEqualTo: adoptionId)
        .where('participants', arrayContains: currentUser!.id)
        .get();

    for (var doc in querySnapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      if (participants.contains(peerId)) {
        return doc.id; // Return existing chat ID
      }
    }

    // Create new chat thread
    final newChatId = const Uuid().v4();
    final newThread = ChatThreadModel(
      id: newChatId,
      participants: [currentUser!.id, peerId],
      participantNames: {
        currentUser!.id: currentUser!.name,
        peerId: peerName,
      },
      lastMessage: 'Sohbet oluşturuldu',
      lastMessageTime: DateTime.now(),
      adoptionId: adoptionId,
      adoptionTitle: adoptionTitle,
      chatType: 'adoption',
      status: 'active',
    );

    await _firestore.collection('chat_threads').doc(newChatId).set(newThread.toMap());
    
    // System welcome message
    final systemMessage = MessageModel(
      id: const Uuid().v4(),
      senderId: 'system',
      text: 'Sahiplendirme ilanı için sohbet başlatıldı: $adoptionTitle',
      timestamp: DateTime.now(),
    );
    await _firestore.collection('chat_threads').doc(newChatId).collection('messages').doc(systemMessage.id).set({
      'senderId': systemMessage.senderId,
      'text': systemMessage.text,
      'type': systemMessage.type,
      'timestamp': Timestamp.fromDate(systemMessage.timestamp),
    });

    return newChatId;
  }

  Stream<List<ChatThreadModel>> getUserChatsStream() {
    if (currentUser == null) return Stream.value([]);
    return _firestore
        .collection('chat_threads')
        .where('participants', arrayContains: currentUser!.id)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) => ChatThreadModel.fromMap(doc.id, doc.data())).toList();
          list.sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));
          return list;
        });
  }

  Future<void> sendAdoptionMessage(String chatId, String text) async {
    if (currentUser == null) return;
    
    final messageId = const Uuid().v4();
    final message = MessageModel(
      id: messageId,
      senderId: currentUser!.id,
      text: text,
      timestamp: DateTime.now(),
    );

    await _firestore
        .collection('chat_threads')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'senderId': message.senderId,
      'text': message.text,
      'type': message.type,
      'timestamp': Timestamp.fromDate(message.timestamp),
    });

    await _firestore.collection('chat_threads').doc(chatId).update({
      'lastMessage': text,
      'lastMessageTime': Timestamp.now(),
    });
  }

  Stream<List<MessageModel>> getAdoptionMessagesStream(String chatId) {
    return _firestore
        .collection('chat_threads')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => MessageModel.fromMap(doc.id, doc.data())).toList();
        });
  }
}
