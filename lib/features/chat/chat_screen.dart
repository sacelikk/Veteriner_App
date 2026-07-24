import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';

class ChatScreen extends ConsumerWidget {
  final String role; // "Pet Sahibi" veya "Veteriner Hekim"

  const ChatScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mesaj listesini dinliyoruz
    final messages = ref.watch(chatProvider);
    final messageController = TextEditingController();
    
    // Geçerli kullanıcıyı almak için
    final db = ref.read(databaseProvider);
    final currentUser = db.currentUser;

    // Karşı tarafın adı
    final String peerName = role == "Pet Sahibi" ? "Vet. Dr. Ayşe" : "Ahmet Y. (Tarçın)";

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.teal),
            ),
            const SizedBox(width: 12),
            Text(peerName, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Görüntülü arama yakında eklenecek!')),
              );
            },
          ),
          if (role == "Veteriner Hekim")
            IconButton(
              icon: const Icon(Icons.note_add),
              onPressed: () {
                // TODO: Tavsiye notu yazıp görüşmeyi bitir
              },
              tooltip: "Tavsiye Notu ile Bitir",
            ),
        ],
      ),
      body: Column(
        children: [
          // Kalan Süre Uyarısı
          Container(
            width: double.infinity,
            color: Colors.orange[100],
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: const Text(
              'Görüşme Süresi: 19:45',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
            ),
          ),
          
          // Mesajlar Listesi
          Expanded(
            child: messages.when(
              data: (msgList) {
                if (msgList.isEmpty) {
                  return const Center(child: Text("Henüz mesaj yok."));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: msgList.length,
                  itemBuilder: (context, index) {
                    final message = msgList[index];
                    // Mesajı gönderen biz miyiz?
                    final isMe = currentUser != null && message.senderId == currentUser.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? Colors.teal : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius.circular(isMe ? 16 : 0),
                            bottomRight: Radius.circular(isMe ? 0 : 16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              message.text,
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.timeFormatted,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Hata: $error')),
            ),
          ),

          // Mesaj Yazma Alanı
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {
                    // TODO: Medya gönder
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      if (messageController.text.trim().isEmpty) return;
                      // Firebase'e mesajı yolla (sabit test_chat_room idsine)
                      db.sendMessage(messageController.text, 'test_chat_room');
                      messageController.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
