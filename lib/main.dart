import 'package:flutter/material.dart';
import 'package:helloworld/video_player.dart';
import 'package:helloworld/video_player_detail.dart';
import 'package:video_player/video_player.dart' as player;

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
        // body: const Center(child: VideoPlayer(),),
      ),
      routes: {
        '/': (context) => ParentPlayer(),
        '/player1': (context) => VideoPlayer(),
        '/player2': (context) => VideoPlayer2()
      },
    );
  }
}

class ParentPlayer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _ParentPlayerState();
}

class _ParentPlayerState extends State<ParentPlayer> {
  late player.VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = player.VideoPlayerController.network(
      "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd",
      videoPlayerOptions: player.VideoPlayerOptions(
        allowBackgroundPlayback: true,
      ),
    )..initialize().then((value) => setState(() => {}));

    _controller.setLooping(true);
    _controller.addListener(listener);
  }

  void listener() {
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ParentPlayerData(
        child: VideoPlayer(),
        controller: _controller,
      )
    ]);
  }
}

class ParentPlayerData extends InheritedWidget {
  final player.VideoPlayerController controller;

  ParentPlayerData({
    required super.child,
    required this.controller,
  });

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }

  static ParentPlayerData? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ParentPlayerData>();
  }
}
