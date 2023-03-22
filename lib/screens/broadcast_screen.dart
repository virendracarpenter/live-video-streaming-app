import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:streaming_app/config/appid.dart';
import 'package:streaming_app/models/user.dart';
import 'package:streaming_app/providers/user_provider.dart';
import 'package:streaming_app/resources/firestore_methods.dart';
import 'package:streaming_app/responsive/responsive_layout.dart';
import 'package:streaming_app/screens/home_screen.dart';
import 'package:http/http.dart' as http;
import 'package:streaming_app/widgets/custom_button.dart';
import '../widgets/chat.dart';

class BroadcastScreen extends StatefulWidget {
  final bool isBroadcaster;
  final String channelId;
  const BroadcastScreen({
    super.key,
    required this.isBroadcaster,
    required this.channelId,
  });

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  late final RtcEngine _engine;
  List<int> remoteUid = [];
  bool switchCamera = true;
  bool isMuted = false;
  bool isScreenSharing = false;

  @override
  void initState() {
    super.initState();
    _initEngine();
  }

  void _initEngine() async {
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _addListeners();

    await _engine.enableVideo();
    await _engine.startPreview();

    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    if (widget.isBroadcaster) {
      _engine.setClientRole(ClientRole.Broadcaster);
    } else {
      _engine.setClientRole(ClientRole.Audience);
    }

    _joinChannel();
  }

  String baseuUrl = "http://192.168.142.192:8080";

  String? token;

  Future<void> getToken() async {
    final res = await http.get(
      Uri.parse(
          '$baseuUrl/rtc/${widget.channelId}/publisher/userAccount/${Provider.of<UserProvider>(context, listen: false).user.uid}/'),
    );

    if (res.statusCode == 200) {
      setState(() {
        token = res.body;
        token = jsonDecode(token!)['rtcToken'];
      });
    } else {
      debugPrint('Failed Fectching Token');
    }
  }

  void _addListeners() {
    // Register the event handler
    _engine.setEventHandler(
      RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
        debugPrint("Local user uid:$uid joined the channel $channel $elapsed");
      }, userJoined: (uid, elapsed) {
        debugPrint("Remote user uid:$uid joined the channel $elapsed");
        setState(() {
          remoteUid.add(uid);
        });
      }, userOffline: (uid, reason) {
        debugPrint("Remote user uid:$uid left the channel $reason");
        setState(() {
          remoteUid.removeWhere((element) => element == uid);
        });
      }, leaveChannel: (stats) {
        debugPrint("Remote user leaved the channel $stats");
        setState(() {
          remoteUid.clear();
        });
      }, tokenPrivilegeWillExpire: (token) async {
        await getToken();
        await _engine.renewToken(token);
      }),
    );
  }

  void _joinChannel() async {
    await getToken();
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
    await _engine.joinChannelWithUserAccount(
      token,
      widget.channelId, //widget.channelId,
      Provider.of<UserProvider>(context, listen: false).user.uid,
    );
  }

  void _switchCamera() {
    _engine.switchCamera().then((value) {
      setState(() {
        switchCamera = !switchCamera;
      });
    }).catchError((error) {
      debugPrint('switchCamera $error');
    });
  }

  void onToggleMute() async {
    setState(() {
      isMuted = !isMuted;
    });
    _engine.muteLocalAudioStream(isMuted);
  }

  _startScreenShare() async {
    final helper = await _engine.getScreenShareHelper(
      appGroup:
          kIsWeb || Platform.isLinux || Platform.isWindows ? null : 'io.agora',
    );
    await helper.disableAudio();
    await helper.enableVideo();
    await helper.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await helper.setClientRole(ClientRole.Broadcaster);

    var windowId = 0;
    var random = Random();
    if (!kIsWeb &&
        (Platform.isWindows ||
            Platform.isMacOS ||
            Platform.isAndroid ||
            Platform.isLinux)) {
      final windows = _engine.enumerateWindows();
      if (windows.isNotEmpty) {
        final index = random.nextInt(windows.length - 1);
        debugPrint('ScreenSharing Windows with index $index');
        windowId = windows[index].id;
      }
    }

    await helper.startScreenCaptureByWindowId(windowId);
    setState(() {
      isScreenSharing = true;
    });
    await helper.joinChannelWithUserAccount(
      token,
      widget.channelId,
      Provider.of<UserProvider>(context, listen: false).user.uid,
    );
  }

  _stopScreenShare() async {
    final helper = await _engine.getScreenShareHelper();
    await helper.destroy().then((value) {
      setState(() {
        isScreenSharing = false;
      });
    }).catchError((err) {
      debugPrint('StopScreenShare $err');
    });
  }

  _leaveChannel() async {
    await _engine.leaveChannel();
    if ('${Provider.of<UserProvider>(context, listen: false).user.uid}${Provider.of<UserProvider>(context, listen: false).user.username}' ==
        widget.channelId) {
      await FirestoreMethods().endLiveStream(widget.channelId);
    } else {
      await FirestoreMethods().updateViewCount(widget.channelId, false);
    }
    Navigator.pushReplacementNamed(context, HomeScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    return WillPopScope(
      onWillPop: () async {
        await _leaveChannel();
        return Future.value(true);
      },
      child: Scaffold(
        bottomNavigationBar: widget.isBroadcaster
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: CustomButton(onTap: _leaveChannel, text: 'End Stream'),
              )
            : null,
        body: Padding(
          padding: const EdgeInsetsDirectional.all(8),
          child: ResponsiveLayout(
            desktop: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _renderVideo(user, isScreenSharing),
                      if ("${user.uid}${user.username}" == widget.channelId)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: _switchCamera,
                              child: const Text('Switch Camera'),
                            ),
                            InkWell(
                              onTap: onToggleMute,
                              child: Text(isMuted ? 'Unmute' : 'Mute'),
                            ),
                            InkWell(
                              onTap: isScreenSharing
                                  ? _stopScreenShare()
                                  : _startScreenShare,
                              child: Text(isScreenSharing
                                  ? 'Stop ScreenShare'
                                  : 'Start ScreenSharing'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Chat(channelId: widget.channelId),
              ],
            ),
            mobile: Column(
              children: [
                _renderVideo(user, isScreenSharing),
                if ("${user.uid}${user.username}" == widget.channelId)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _switchCamera,
                        child: const Text('Switch Camera'),
                      ),
                      InkWell(
                        onTap: onToggleMute,
                        child: Text(isMuted ? 'Unmute' : 'Mute'),
                      ),
                    ],
                  ),
                Expanded(
                  child: Chat(
                    channelId: widget.channelId,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _renderVideo(user, isScreenSharing) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: "${user.uid}${user.username}" == widget.channelId
          ? isScreenSharing
              ? kIsWeb
                  ? const rtc_local_view.SurfaceView.screenShare()
                  : const rtc_local_view.TextureView.screenShare()
              : const rtc_local_view.SurfaceView(
                  zOrderMediaOverlay: true,
                  zOrderOnTop: true,
                )
          : isScreenSharing
              ? kIsWeb
                  ? const rtc_local_view.SurfaceView.screenShare()
                  : const rtc_local_view.TextureView.screenShare()
              : remoteUid.isNotEmpty
                  ? kIsWeb
                      ? rtc_remote_view.SurfaceView(
                          uid: remoteUid[0],
                          channelId: widget.channelId,
                        )
                      : rtc_remote_view.TextureView(
                          uid: remoteUid[0],
                          channelId: widget.channelId,
                        )
                  : Container(),
    );
  }
}
