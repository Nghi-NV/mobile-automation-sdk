import 'package:flutter/material.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{project_name_pascal}}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Container(), // TODO: Add home page
    );
  }
}
