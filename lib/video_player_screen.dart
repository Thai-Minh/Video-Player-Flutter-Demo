import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helloworld/custom/player_slider.dart';
import 'package:video_player/video_player.dart';

import 'custom/player_path_painter.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  bool validPosition = false;

  ui.Image? customImage1;
  ui.Image? customImage2;

  PlayerIndicatorShape player = const PlayerIndicatorShape();

  var widgetKey = GlobalKey();
  var _widgetSize = Size(-1, -1);

  Future<ui.Image> load(String asset) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

  @override
  void initState() {
    load('assets/images/twitter.png').then((image) {
      setState(() {
        customImage1 = image;
      });
    });

    load('assets/images/google.png').then((image) {
      setState(() {
        customImage2 = image;
      });
    });

    super.initState();

    _controller = VideoPlayerController.network(
        "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd");

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.addListener(listener);
  }

  void listener() async {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      var cPosition = _controller.value.position;
      var cDuration = _controller.value.duration;
      if (cDuration.inHours == 0) {
        var strPosition = cPosition.toString().split('.')[0];
        var strDuration = cDuration.toString().split('.')[0];
        position = "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
        duration = "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
      } else {
        position = cPosition.toString().split('.')[0];
        duration = cDuration.toString().split('.')[0];
      }
      validPosition = cDuration.compareTo(cPosition) >= 0;
      sliderValue = validPosition ? cPosition.inSeconds.toDouble() : 0;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext? context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      var currSize = widgetKey.currentContext!.size!;
      if (currSize.width != _widgetSize.width ||
          currSize.height != _widgetSize.height) {
        _widgetSize = currSize;
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              color: Colors.black,
              child: Column(children: <Widget>[
                AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller)),
                Column(
                    key: widgetKey,
                    children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue[700],
                      inactiveTrackColor: Colors.blue[100],
                      trackShape: const RoundedRectSliderTrackShape(),
                      trackHeight: 4.0,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                      thumbColor: Colors.blueAccent,
                      overlayColor: Colors.red.withAlpha(32),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 28.0),
                      tickMarkShape: const RoundSliderTickMarkShape(),
                      activeTickMarkColor: Colors.blue[700],
                      inactiveTickMarkColor: Colors.blue[100],
                      valueIndicatorColor: Colors.red,
                      valueIndicatorTextStyle: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    child: PlayerSlider(
                      value: sliderValue,
                      min: 0.0,
                      max: (!validPosition)
                          ? 1.0
                          : _controller.value.duration.inSeconds.toDouble(),
                      label: position,
                      divisions: _controller.value.duration.inSeconds,
                      onChanged:
                          validPosition ? _onSliderPositionChanged : null,
                      image: sliderValue % 20 == 0 ? customImage2 : customImage1,
                      player: player,
                    ),
                  ),
                ])
              ]),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            if (_controller.value.isPlaying) {
              _controller.pause();
            } else {
              _controller.play();
            }
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }

  void _onSliderPositionChanged(double progress) {
    setState(() {
      sliderValue = progress.floor().toDouble();
    });
    setTime(sliderValue.toInt() * 1000);
  }

  Future<void> setTime(int time) async {
    return await _controller.seekTo(Duration(milliseconds: time));
  }
}
