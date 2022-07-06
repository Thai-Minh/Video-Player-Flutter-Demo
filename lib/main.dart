import 'package:flutter/material.dart';
import 'package:helloworld/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Player Flutter Demo',
      // home: VideoPlayerScreen(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Video Player"),
        ),
        body:  const Center(child: VideoPlayer(),),
      ),
    );
  }
}
