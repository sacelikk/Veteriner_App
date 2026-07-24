import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/pet_model.dart';
import '../models/message_model.dart';

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

  // Giriş Yapma (E-posta ve Şifre)
  Future<void> loginWithEmail(String email, String password) async {
    try {
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      String uid = userCred.user!.uid;

      // Firestore'dan rol ve isim bilgisini çek
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentUser = UserModel(
          id: uid,
          email: data['email'] ?? email,
          role: data['role'] ?? 'Pet Sahibi',
          name: data['name'] ?? 'İsimsiz',
        );
      } else {
        throw Exception("Kullanıcı verisi bulunamadı!");
      }
    } catch (e) {
      throw Exception("Giriş Hatası: $e");
    }
  }

  // Oturumu Kapat
  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
  }

  // Aktif Oturumu Kontrol Etme (Uygulama açılışında çalışacak)
  Future<UserModel?> checkCurrentUser() async {
    User? firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        currentUser = UserModel(
          id: firebaseUser.uid,
          email: data['email'] ?? firebaseUser.email!,
          role: data['role'] ?? 'Pet Sahibi',
          name: data['name'] ?? 'İsimsiz',
        );
        return currentUser;
      }
    }
    return null;
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
          final requests = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
          // Hata vermemesi için sıralamayı Firestore sorgusuyla değil, uygulama içinde yapıyoruz.
          requests.sort((a, b) {
            final aTime = a['createdAt'] as Timestamp?;
            final bTime = b['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // Yeniden eskiye (descending)
          });
          return requests;
        });
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
