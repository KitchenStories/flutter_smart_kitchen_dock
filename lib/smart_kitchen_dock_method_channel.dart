import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'smart_kitchen_dock_platform_interface.dart';

/// An implementation of [SmartKitchenDockPlatform] that uses method channels.
class MethodChannelSmartKitchenDock extends SmartKitchenDockPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('smart_kitchen_dock');

  final eventChannel = const EventChannel("smart_kitchen_dock_events");

  StreamSubscription? events;

  StreamController<Gesture>? controller;

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  bool handleKeyboard(KeyEvent event) {
    if (event is KeyDownEvent) {
      return false;
    }
    switch (event.logicalKey.keyId) {
      // up
      case 0x100000304:
        controller?.add(Gesture.up);
        return true;
      // down
      case 0x100000301:
        controller?.add(Gesture.down);
        return true;
      // left
      case 0x100000302:
        controller?.add(Gesture.left);
        return true;
      // right
      case 0x100000303:
        controller?.add(Gesture.right);
        return true;
      default:
        return false;
    }
  }

  @override
  Stream<Gesture> gestures() {
    if (controller != null) {
      return controller!.stream;
    }
    if (Platform.isAndroid) {
      controller = StreamController<Gesture>(onListen: () async {
        HardwareKeyboard.instance.addHandler(handleKeyboard);
      }, onCancel: () {
        HardwareKeyboard.instance.removeHandler(handleKeyboard);
        controller = null;
      });
      return controller!.stream;
    }
    controller = StreamController<Gesture>(onListen: () async {
      events?.cancel();
      events ??= eventChannel.receiveBroadcastStream().listen((data) {
        controller?.add(
            Gesture.values.byName((data["data"] as String).toLowerCase()));
      });
    }, onCancel: () {
      events?.cancel();
      events = null;
      controller = null;
    });
    return controller!.stream;
  }
}
