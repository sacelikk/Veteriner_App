import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/fake_database.dart';
import 'video_call_screen.dart';

class GlobalCallListener extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalCallListener({super.key, required this.child});

  @override
  ConsumerState<GlobalCallListener> createState() => _GlobalCallListenerState();
}

class _GlobalCallListenerState extends ConsumerState<GlobalCallListener> {
  String? _currentlyRingingCallId;

  @override
  Widget build(BuildContext context) {
    // Gelen aramaları dinleyelim
    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(
      incomingCallsProvider,
      (previous, next) {
        next.whenData((calls) {
          if (calls.isNotEmpty) {
            final activeCall = calls.first;
            final callId = activeCall['id'];
            final callerName = activeCall['callerName'] ?? 'Bilinmeyen Arayan';

            if (_currentlyRingingCallId != callId) {
              _currentlyRingingCallId = callId;
              _showIncomingCallDialog(callId, callerName);
            }
          } else {
            // Arama kapandıysa veya iptal edildiyse, açıksa dialogu kapatabiliriz
            // Ancak bu basitlikte kalsın. Dialog zaten reject/accept ile kapanıyor.
          }
        });
      },
    );

    return widget.child;
  }

  void _showIncomingCallDialog(String callId, String callerName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Gelen Görüntülü Arama 📞', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                '$callerName sizi arıyor...',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await db.updateCallStatus(callId, 'rejected');
                _currentlyRingingCallId = null;
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Reddet', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final db = ref.read(databaseProvider);
                await db.updateCallStatus(callId, 'accepted');
                _currentlyRingingCallId = null;
                if (context.mounted) {
                  Navigator.pop(dialogContext); // Dialogu kapat
                  // Kamera ekranına git
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VideoCallScreen(channelName: callId),
                    ),
                  );
                }
              },
              child: const Text('Kabul Et', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
