import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:async';

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

  @override
  Future<String?> startListening() {
    return Future.value("");
    //return methodChannel.invokeMethod<String>('startListening');
  }

  @override
  Stream<Gesture> gestures() {
    if (controller != null) {
      return controller!.stream;
    }
    controller = StreamController<Gesture>(onListen: () async {
      events?.cancel();
      events ??= eventChannel.receiveBroadcastStream().listen((data) {
        print("Received data ${data}");
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

  @override
  Future<String?> stopListening() async {
    //final res = methodChannel.invokeMethod<String>('stopListening');
    await events?.cancel();
    events = null;
    return "";
  }
}
