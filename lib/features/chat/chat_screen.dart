import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';
import '../../theme/app_theme.dart';
import 'video_call_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String role; // "Pet Sahibi" veya "Veteriner Hekim"
  final String chatId; // Hangi sohbet odası?

  const ChatScreen({super.key, required this.role, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  bool _isIncomingDialogShowing = false;
  bool _isCallingDialogShowing = false;

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(widget.chatId));
    final db = ref.read(databaseProvider);
    final currentUser = db.currentUser;
    final String peerName = widget.role == "Pet Sahibi" ? "Vet. Dr. Ayşe" : "Ahmet Y. (Tarçın)";

    ref.listen<AsyncValue<Map<String, dynamic>?>>(
      supportRequestStatusProvider(widget.chatId),
      (previous, next) {
        final data = next.value;
        if (data == null || currentUser == null) return;

        final isCalling = data['isCalling'] ?? false;
        final callerId = data['callerId'];
        final callAccepted = data['callAccepted'] ?? false;
        final callDeclined = data['callDeclined'] ?? false;

        // 1. Gelen Arama (Ben aramıyorum)
        if (isCalling && callerId != currentUser.id && !_isIncomingDialogShowing) {
          _isIncomingDialogShowing = true;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text("Gelen Görüntülü Arama"),
              content: const Text("Karşı taraf sizi görüntülü arıyor..."),
              actions: [
                TextButton(
                  onPressed: () {
                    db.declineVideoCall(widget.chatId);
                    Navigator.pop(context);
                    _isIncomingDialogShowing = false;
                  },
                  child: const Text("Reddet", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    db.acceptVideoCall(widget.chatId);
                    Navigator.pop(context);
                    _isIncomingDialogShowing = false;
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoCallScreen(channelName: widget.chatId),
                      ),
                    );
                  },
                  child: const Text("Kabul Et"),
                ),
              ],
            ),
          );
        }

        // 2. Arama Reddedildi (Ben aradım ve reddedildi)
        if (callDeclined && callerId == currentUser.id) {
          if (_isCallingDialogShowing) {
            Navigator.pop(context);
            _isCallingDialogShowing = false;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Arama karşı tarafça reddedildi.")),
          );
          db.resetCallStatus(widget.chatId);
        }

        // 3. Arama Kabul Edildi (Ben aradım ve kabul edildi)
        if (callAccepted && callerId == currentUser.id) {
          if (_isCallingDialogShowing) {
            Navigator.pop(context);
            _isCallingDialogShowing = false;
          }
          db.resetCallStatus(widget.chatId);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(channelName: widget.chatId),
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Text(peerName, style: const TextStyle(fontSize: 16)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Aramanın başladığına dair otomatik bir mesaj gönder
              db.sendMessage("📞 Görüntülü arama başlatıldı.", widget.chatId);
              
              // Veritabanında arama durumunu başlat
              db.startVideoCall(widget.chatId);
              
              _isCallingDialogShowing = true;
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text("Aranıyor..."),
                  content: const Text("Karşı tarafın kabul etmesi bekleniyor."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        db.resetCallStatus(widget.chatId);
                        Navigator.pop(context);
                        _isCallingDialogShowing = false;
                      },
                      child: const Text("İptal Et", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
          if (widget.role == "Veteriner Hekim")
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
            color: Colors.orange.shade100,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Görüşme Süresi: 19:45',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
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
                    final isMe = currentUser != null && message.senderId == currentUser.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.primaryColor : Colors.white,
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
                                color: isMe ? Colors.white : AppTheme.textDark,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              message.timeFormatted,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : AppTheme.textLight,
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
                  icon: const Icon(Icons.attach_file, color: AppTheme.textLight),
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.accentColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      if (messageController.text.trim().isEmpty) return;
                      db.sendMessage(messageController.text, widget.chatId);
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
