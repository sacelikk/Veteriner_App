import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

const appId = "b04c1f1952e0440bb190bc1827b22b01"; 
const token = "007eJxTYLgloH3Br5fjQqdtl4RShENKE/NswQsHtDf3x+54cGnzXFsFhiQDk2TDNENLU6NUAxMTg6QkQ0uDpGRDCyPzJCOjJAPDHrXUrIZARob7V6UZmBgYGViAGMRnApPMYJIFTPIwpKTm5usmZyTm5aXmMIBVM0LlDQ0MDAFECiTr";
const defaultChannel = "demo-channel";

class VideoCallScreen extends StatefulWidget {
  final String channelName;

  const VideoCallScreen({super.key, required this.channelName});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  String? _agoraErrorMessage;
  late String _activeChannel;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    _activeChannel = token.isNotEmpty 
        ? defaultChannel 
        : (widget.channelName.isNotEmpty ? widget.channelName : defaultChannel);
    initAgora();
  }

  Future<void> initAgora() async {
    // 1. İzinleri al (Kamera ve Mikrofon)
    final statuses = await [Permission.microphone, Permission.camera].request();
    if (statuses[Permission.camera] != PermissionStatus.granted ||
        statuses[Permission.microphone] != PermissionStatus.granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Görüntülü görüşme için kamera ve mikrofon izni gereklidir.')),
      );
      return;
    }

    // 2. Motoru başlat
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. Olay Dinleyicileri (Event Handlers)
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("Yerel kullanıcı katıldı: ${connection.localUid} (Kanal: ${connection.channelId})");
          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _agoraErrorMessage = null;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("Uzak kullanıcı katıldı: $remoteUid");
          if (mounted) {
            setState(() {
              _remoteUid = remoteUid;
            });
          }
        },
        onRemoteVideoStateChanged: (RtcConnection connection, int remoteUid, RemoteVideoState state, RemoteVideoStateReason reason, int elapsed) {
          debugPrint("Uzak video değişti: $remoteUid -> $state");
          if (state == RemoteVideoState.remoteVideoStateDecoding || state == RemoteVideoState.remoteVideoStateStarting) {
            if (mounted) {
              setState(() {
                _remoteUid = remoteUid;
              });
            }
          }
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("Uzak kullanıcı ayrıldı: $remoteUid");
          if (mounted) {
            setState(() {
              _remoteUid = null;
            });
          }
        },
        onError: (ErrorCodeType err, String msg) {
          debugPrint("Agora Hata ($err): $msg");
          if (err == ErrorCodeType.errInvalidToken || err == ErrorCodeType.errTokenExpired) {
            if (mounted) {
              setState(() {
                _agoraErrorMessage =
                    'Agora Geçersiz Token Hatası (errInvalidToken)\n\nAgora Console üzerindeki token süresi dolmuş veya kanal adı eşleşmiyor.';
              });
            }
          }
        },
      ),
    );

    // 4. Videoyu aktif et ve odaya yayın yapacak şekilde katıl
    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.joinChannel(
      token: token,
      channelId: _activeChannel,
      uid: 0, // 0 verirsek Agora rastgele benzersiz bir UID atar
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  // Kamera Kapama / Sessize Alma / Kapatma butonları
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: () {
              setState(() {
                _muted = !_muted;
              });
              _engine.muteLocalAudioStream(_muted);
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _muted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _muted ? Icons.mic_off : Icons.mic,
              color: _muted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context), // Aramayı Kapat
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () {
              _engine.switchCamera();
            },
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: const Icon(
              Icons.switch_camera,
              color: Colors.blueAccent,
              size: 20.0,
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  // Karşı tarafın video akışı
  Widget _remoteVideo() {
    if (_agoraErrorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text(
              _agoraErrorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ],
        ),
      );
    }

    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: _activeChannel),
        ),
      );
    } else {
      return const Center(
        child: Text(
          'Karşı taraf bekleniyor...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Görüntülü Görüşme'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          if (_localUserJoined)
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 100,
                  height: 150,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _toolbar(),
        ],
      ),
    );
  }
}
