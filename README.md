# smart_kitchen_dock

Flutter plugin used to receive messsages from smart kitchen dock devices

## Quick Start 🚀 #

```dart
final smartKitchenDock = SmartKitchenDock();

// listen to gesture messageSize
final subscription = smartKitchenDock.gestures().listen((gesture) {
    if (gesture == Gesture.down) {
        // scroll down
    }
});

// stop listening to messages
subscription.cancel()
```

## Setup

### iOS
1. Setup the smart kitchen dock and pair your iOS device with it
2. Make sure the `Supported external accessory protocols` Info.plist in iOS-project of your app contains the
smart kitchen dock protocol string `com.smartkitchendock.protocol2`
