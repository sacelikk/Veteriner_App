import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fake_database.dart'; // To get databaseProvider

final callServiceProvider = Provider<CallService>((ref) {
  final db = ref.watch(databaseProvider);
  return CallService(db);
});

final incomingCallsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final callService = ref.watch(callServiceProvider);
  return callService.getIncomingCallsStream();
});

final callStatusProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, callId) {
  final callService = ref.watch(callServiceProvider);
  return callService.getCallStatusStream(callId);
});

class CallService {
  final dynamic _db; // use dynamic to avoid typing issues if fake_database is weird
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CallService(this._db);

  Future<void> initiateCall(String chatId) async {
    final currentUser = _db.currentUser;
    if (currentUser == null) return;
    
    final doc = await _firestore.collection('support_requests').doc(chatId).get();
    if (!doc.exists) return;
    
    final data = doc.data()!;
    final String receiverId = currentUser.role == "Pet Sahibi" ? data['vetId'] : data['petOwnerId'];

    await _firestore.collection('calls').doc(chatId).set({
      'callerId': currentUser.id,
      'callerName': currentUser.name,
      'receiverId': receiverId,
      'chatId': chatId,
      'status': 'calling',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCallStatus(String callId, String status) async {
    await _firestore.collection('calls').doc(callId).update({
      'status': status,
    });
  }

  Stream<List<Map<String, dynamic>>> getIncomingCallsStream() {
    return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
      if (user == null) {
        return Stream.value([]);
      }
      return _firestore
          .collection('calls')
          .where('receiverId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'calling')
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
    });
  }

  Stream<Map<String, dynamic>?> getCallStatusStream(String callId) {
    return _firestore.collection('calls').doc(callId).snapshots().map((doc) {
      if (doc.exists) return {'id': doc.id, ...doc.data()!};
      return null;
    });
  }
}
