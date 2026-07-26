import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../services/database_providers.dart';
import '../../theme/app_theme.dart';
import 'adoption_chat_screen.dart';
import 'chat_screen.dart';

class MyChatsScreen extends ConsumerWidget {
  const MyChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(userChatsProvider);
    final db = ref.watch(databaseProvider);
    final currentUser = db.currentUser;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Mesajlarım'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: AppTheme.accentColor,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Sahiplendirme'),
              Tab(text: 'Canlı Destek'),
            ],
          ),
        ),
        body: currentUser == null
            ? const Center(child: Text('Lütfen giriş yapın.'))
            : chatsAsync.when(
                data: (chats) {
                  final adoptionChats = chats.where((c) => c.chatType != 'vet_support').toList();
                  final vetChats = chats.where((c) => c.chatType == 'vet_support').toList();

                  return TabBarView(
                    children: [
                      _buildChatList(context, currentUser, adoptionChats),
                      _buildChatList(context, currentUser, vetChats),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Hata: $err')),
              ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context, dynamic currentUser, List<dynamic> chats) {
    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.primaryLight.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Henüz bir mesajınız bulunmuyor.',
              style: TextStyle(color: AppTheme.textLight, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        
        // Kendi ID'mizi hariç tutarak karşı tarafın adını bulalım
        String peerName = 'Bilinmeyen Kullanıcı';
        chat.participantNames.forEach((key, value) {
          if (key != currentUser.id) {
            peerName = value;
          }
        });

        final timeFormatted = DateFormat('HH:mm').format(chat.lastMessageTime);
        final isClosed = chat.status == 'closed';
        final isVetSupport = chat.chatType == 'vet_support';

        return Card(
          elevation: 1,
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Stack(
              children: [
                CircleAvatar(
                  backgroundColor: isVetSupport 
                      ? Colors.blue.withOpacity(0.2) 
                      : AppTheme.accentColor.withOpacity(0.2),
                  child: Icon(
                    isVetSupport ? Icons.medical_services : Icons.pets, 
                    color: isVetSupport ? Colors.blue : AppTheme.accentColor,
                  ),
                ),
                if (isClosed)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    peerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isClosed)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('Kapalı', style: TextStyle(fontSize: 10, color: Colors.red.shade900)),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isVetSupport 
                      ? 'Veteriner Canlı Destek' 
                      : 'İlan: ${chat.adoptionTitle ?? ''}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: isVetSupport ? Colors.blue.shade700 : AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  chat.lastMessage ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: Text(
              timeFormatted,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              if (isVetSupport) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      role: currentUser.role == 'Veteriner Hekim' ? 'Veteriner Hekim' : 'Pet Sahibi',
                      chatId: chat.id,
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdoptionChatScreen(
                      chatId: chat.id,
                      peerName: peerName,
                      adoptionTitle: chat.adoptionTitle ?? 'İlan',
                    ),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}
