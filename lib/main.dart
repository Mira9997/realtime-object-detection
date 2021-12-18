import 'package:flutter/material.dart';
import 'package:mykalori3/MyHomePage.dart';
import 'package:camera/camera.dart';

List<CameraDescription> cameras;

Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyKalori',
      home: HomePage(),
    );
  }
}
