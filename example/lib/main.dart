import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_smart_kitchen_dock/flutter_smart_kitchen_dock.dart';
import 'package:flutter_smart_kitchen_dock/smart_kitchen_dock_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _smartKitchenDockPlugin = SmartKitchenDock();
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    _initPlatformState();
  }

  Future<void> _initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion = await _smartKitchenDockPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on MissingPluginException {
      // The plugin cannot be used for some reason or another!
      return;
    } on PlatformException {
      platformVersion = 'Failed to get platform version';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Platform version: $_platformVersion'),
            StreamBuilder<Gesture>(
              stream: _smartKitchenDockPlugin.gestures(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Icon(
                    switch (snapshot.data) {
                      Gesture.up => CupertinoIcons.arrow_up,
                      Gesture.down => CupertinoIcons.arrow_down,
                      Gesture.left => CupertinoIcons.arrow_left,
                      Gesture.right => CupertinoIcons.arrow_right,
                      _ => CupertinoIcons.question,
                    },
                    color: Colors.pink,
                    weight: 200,
                    size: 64.0,
                  );
                }
                return const Text('Waiting...');
              },
            ),
          ],
        ),
      ),
    );
  }
}
