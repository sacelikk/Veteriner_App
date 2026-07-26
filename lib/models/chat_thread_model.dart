import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThreadModel {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String? lastMessage;
  final DateTime lastMessageTime;
  
  // Sahiplendirme verileri
  final String? adoptionId;
  final String? adoptionTitle;

  // Yeni alanlar: Sohbet Türü ve Durumu
  final String chatType; // 'adoption' veya 'vet_support'
  final String status;   // 'active' veya 'closed'

  ChatThreadModel({
    required this.id,
    required this.participants,
    required this.participantNames,
    this.lastMessage,
    required this.lastMessageTime,
    this.adoptionId,
    this.adoptionTitle,
    this.chatType = 'adoption',
    this.status = 'active',
  });

  factory ChatThreadModel.fromMap(String id, Map<String, dynamic> map) {
    return ChatThreadModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      lastMessage: map['lastMessage'],
      lastMessageTime: (map['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adoptionId: map['adoptionId'],
      adoptionTitle: map['adoptionTitle'],
      chatType: map['chatType'] ?? 'adoption',
      status: map['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'participantNames': participantNames,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'adoptionId': adoptionId,
      'adoptionTitle': adoptionTitle,
      'chatType': chatType,
      'status': status,
    };
  }
}
