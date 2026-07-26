import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import '../../services/database_providers.dart';
import '../../services/firebase_service.dart';
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

  @override
  Widget build(BuildContext context) {
    ref.listen(
      chatThreadProvider(widget.chatId),
      (previous, next) {
        final wasOpen = previous?.value?.status != 'closed';
        final isNowClosed = next.value?.status == 'closed';
        
        if (wasOpen && isNowClosed && widget.role == 'Pet Sahibi') {
          final db = ref.read(databaseProvider);
          final currentUser = db.currentUser;
          final peerId = next.value?.participants.firstWhere((id) => id != currentUser?.id, orElse: () => '');
          if (peerId != null && peerId.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showRatingDialog(context, peerId, db);
            });
          }
        }
      },
    );

    final messages = ref.watch(chatProvider(widget.chatId));
    final chatThreadAsync = ref.watch(chatThreadProvider(widget.chatId));
    final db = ref.read(databaseProvider);
    final currentUser = db.currentUser;
    final String peerName = widget.role == "Pet Sahibi" ? "Veteriner Hekim" : "Pet Sahibi";
    
    final isClosed = chatThreadAsync.value?.status == 'closed';

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
            tooltip: "Görüntülü Görüşme Başlat",
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.sendCallInvite(widget.chatId);
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoCallScreen(channelName: widget.chatId),
                ),
              );
            },
          ),
          if (widget.role == "Veteriner Hekim" && !isClosed)
            IconButton(
              icon: const Icon(Icons.fact_check),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                        SizedBox(width: 8),
                        Expanded(child: Text('Görüşmeyi Sonlandır', overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    content: const Text(
                      'Görüşmeyi sonlandırmak istediğinize emin misiniz?\n\n'
                      'Görüşme süresi kaydedilecek ve pet sahibine değerlendirme (yıldız verme) ekranı gönderilecektir.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context); // İlk dialogu kapat
                          
                          // Sohbeti veritabanında sonlandır
                          await db.closeChat(widget.chatId);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Sonlandır'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: "Görüşmeyi Sonlandır ve Raporla",
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

                    if (message.type == 'call_invite') {
                      if (isMe) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.videocam, color: AppTheme.primaryColor),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Görüntülü Görüşme Daveti Gönderildi 📹',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoCallScreen(channelName: widget.chatId),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.videocam, size: 18),
                                label: const Text('Görüşmeye Katıl'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade400, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.video_call, color: Colors.green, size: 28),
                                  SizedBox(width: 8),
                                  Text(
                                    'Görüntülü Görüşme Çağrısı 📹',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Karşı taraf sizi canlı görüntülü görüşmeye davet ediyor.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await db.rejectCall(widget.chatId, message.id);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Hata: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.call_end, color: Colors.red),
                                    label: const Text('REDDET', style: TextStyle(color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Colors.red),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => VideoCallScreen(channelName: widget.chatId),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.call, color: Colors.white),
                                    label: const Text(
                                      'KATIL',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                    }

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
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Text(
                                'Dosya Gönder',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                child: Icon(Icons.camera_alt, color: Colors.white),
                              ),
                              title: const Text('Kamera'),
                              subtitle: const Text('Fotoğraf veya video çek'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kamera açılıyor...')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.photo_library, color: Colors.white),
                              ),
                              title: const Text('Galeri'),
                              subtitle: const Text('Galeriden fotoğraf veya video seç'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Galeri açılıyor...')),
                                );
                              },
                            ),
                            ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Icon(Icons.insert_drive_file, color: Colors.white),
                              ),
                              title: const Text('Belge'),
                              subtitle: const Text('Tahlil, PDF veya diğer belgeler'),
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Dosya yöneticisi açılıyor...')),
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Consumer(builder: (context, ref, _) {
                    final chat = ref.watch(chatThreadProvider(widget.chatId));
                    final isClosed = chat.maybeWhen(data: (c) => c?.status == 'closed', orElse: () => false);

                    if (isClosed) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Bu görüşme sonlandırılmıştır.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    } else {
                      return TextField(
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
                      );
                    }
                  }),
                ),
                const SizedBox(width: 8),
                Consumer(builder: (context, ref, _) {
                  final chat = ref.watch(chatThreadProvider(widget.chatId));
                  final isClosed = chat.maybeWhen(data: (c) => c?.status == 'closed', orElse: () => false);
                  
                  if (isClosed) return const SizedBox.shrink();

                  return CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: () {
                        if (messageController.text.trim().isEmpty) return;
                        db.sendMessage(messageController.text, widget.chatId);
                        messageController.clear();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String vetId, FirebaseService db) {
    int selectedRating = 5;
    bool isSubmitting = false;
    bool isSuccess = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isSuccess ? 'Teşekkürler!' : 'Veterineri Değerlendirin', textAlign: TextAlign.center),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSuccess) ...[
                    // Başarı durumu - Lottie kullanmak yerine şimdilik flutter_animate veya Icon
                    SizedBox(
                      height: 120,
                      child: Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_lk80fpsm.json', // Example success animation
                        repeat: false,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.check_circle, color: Colors.green, size: 80),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Değerlendirmeniz başarıyla kaydedildi.', textAlign: TextAlign.center),
                  ] else ...[
                    const Text('Görüşmeniz nasıldı?', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return IconButton(
                          icon: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              selectedRating = index + 1;
                            });
                          },
                        );
                      }),
                    ),
                  ],
                ],
              ),
              actions: [
                if (isSuccess)
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kapat'),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Şimdilik Geç', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          setState(() => isSubmitting = true);
                          try {
                            await db.submitVetRating(vetId, selectedRating);
                            if (!context.mounted) return;
                            setState(() {
                              isSubmitting = false;
                              isSuccess = true;
                            });
                          } catch (e) {
                            if (!context.mounted) return;
                            setState(() => isSubmitting = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: isSubmitting 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                           : const Text('Gönder', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
