import 'package:flutter/material.dart';
import 'package:tekartik_prefs_flutter/prefs.dart';
import 'package:tekartik_prefs_flutter/prefs_async.dart';
import 'package:tekartik_prefs_test/prefs_async_test.dart';
import 'package:tekartik_prefs_test/prefs_test.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  var prefsAsyncFactory = prefsAsyncFactoryFlutter;
  runPrefsAsyncTests(prefsAsyncFactory);
  var prefsFactory = prefsFactoryFlutter;
  runPrefsTests(prefsFactory);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(title: const Text('Prefs flutter test'))),
    );
  }
}
