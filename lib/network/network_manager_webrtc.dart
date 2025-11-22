import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'network_manager_interface.dart';

class NetworkManagerImplementation implements NetworkManagerInterface {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();

  @override
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  Future<void> _initializePeerConnection() async {
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceConnectionState = (state) {
      debugPrint('ICE Connection State: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _messageController.add({'type': 'CONNECTED'});
      } else if (state ==
              RTCIceConnectionState.RTCIceConnectionStateDisconnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateClosed) {
        _messageController.add({'type': 'DISCONNECT'});
      }
    };

    _peerConnection!.onDataChannel = (channel) {
      debugPrint('Data channel received: ${channel.label}');
      _setupDataChannel(channel);
    };
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;

    _dataChannel!.onMessage = (RTCDataChannelMessage message) {
      try {
        final data = message.text;
        final json = jsonDecode(data);
        _messageController.add(json);
      } catch (e) {
        debugPrint('Error parsing message: $e');
      }
    };

    _dataChannel!.onDataChannelState = (state) {
      debugPrint('Data channel state changed to: $state');
      _handleDataChannelState(state);
    };

    final initialState = _dataChannel!.state;
    if (initialState != null) {
      debugPrint('Initial data channel state: $initialState');
      _handleDataChannelState(initialState);
    }
  }

  void _handleDataChannelState(RTCDataChannelState state) {
    if (state == RTCDataChannelState.RTCDataChannelOpen) {
      debugPrint('Data channel is open - connection ready!');
      _messageController.add({'type': 'CONNECTED'});

      Future.delayed(const Duration(milliseconds: 100), () {
        send({'type': 'HANDSHAKE'});
      });
    } else if (state == RTCDataChannelState.RTCDataChannelClosed) {
      _messageController.add({'type': 'DISCONNECT'});
    }
  }

  @override
  Future<String> createOffer() async {
    await _initializePeerConnection();

    final dataChannelInit = RTCDataChannelInit();
    _dataChannel = await _peerConnection!.createDataChannel(
      'game_channel',
      dataChannelInit,
    );
    _setupDataChannel(_dataChannel!);

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    await _waitForIceGathering();

    final localDesc = await _peerConnection!.getLocalDescription();
    return jsonEncode(localDesc!.toMap());
  }

  @override
  Future<String> createAnswer(String offer) async {
    await _initializePeerConnection();

    final offerMap = jsonDecode(offer);
    final remoteDesc = RTCSessionDescription(offerMap['sdp'], offerMap['type']);
    await _peerConnection!.setRemoteDescription(remoteDesc);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    await _waitForIceGathering();

    final localDesc = await _peerConnection!.getLocalDescription();
    return jsonEncode(localDesc!.toMap());
  }

  @override
  Future<void> completeConnection(String answer) async {
    final answerMap = jsonDecode(answer);
    final remoteDesc = RTCSessionDescription(
      answerMap['sdp'],
      answerMap['type'],
    );
    await _peerConnection!.setRemoteDescription(remoteDesc);
  }

  Future<void> _waitForIceGathering() async {
    final completer = Completer<void>();

    _peerConnection!.onIceGatheringState = (state) {
      debugPrint('ICE Gathering State: $state');
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    };

    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('ICE gathering timeout - continuing anyway');
      },
    );
  }

  @override
  void send(Map<String, dynamic> data) {
    if (_dataChannel != null &&
        _dataChannel!.state == RTCDataChannelState.RTCDataChannelOpen) {
      final msg = jsonEncode(data);
      _dataChannel!.send(RTCDataChannelMessage(msg));
    } else {
      debugPrint('Data channel not ready. State: ${_dataChannel?.state}');
    }
  }

  @override
  void dispose() {
    _dataChannel?.close();
    _peerConnection?.close();
    _messageController.close();
  }
}
