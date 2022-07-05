import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'advanced_overlay_widget.dart';
import 'custom/player_path_painter.dart';
import 'image_repository.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<StatefulWidget> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  var widthScreen = 0.0;

  double sliderValue = 0.0;
  String position = '';
  String duration = '';
  bool validPosition = false;

  bool isDragging = false;

  double transX = 0.0;

  List<Image> images = [];
  List<ui.Image> images2 = [];

  PlayerIndicatorShape indicatorShape = const PlayerIndicatorShape();

  Orientation target = Orientation.portrait;
  static const double _overloadPadding = 10;

  @override
  void initState() {
    // test 1
    var imagesFuture1 = RenderBitmap().getImageSourceFormUrl(
        "https://i.ytimg.com/sb/hkP4tVTdsz8/storyboard3_L2/M0.jpg?sqp=-oaymwENSDfyq4qpAwVwAcABBqLzl_8DBgjFrO-VBg==&sigh=rs\$AOn4CLBo_Qgn_lqi6XFJZ5oJxiNRWjCCfA",
        5,
        5);

    imagesFuture1
        .then((value) => {images = value.map((e) => Image.memory(e)).toList()});

    // test 2
    var imagesFuture2 = RenderBitmap().getUiImageFormUrl(
        "https://i.ytimg.com/sb/hkP4tVTdsz8/storyboard3_L2/M0.jpg?sqp=-oaymwENSDfyq4qpAwVwAcABBqLzl_8DBgjFrO-VBg==&sigh=rs\$AOn4CLBo_Qgn_lqi6XFJZ5oJxiNRWjCCfA",
        5,
        5);

    imagesFuture2.then((value) => {images2 = value});

    super.initState();

    _controller = VideoPlayerController.network(
        "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd",
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true));

    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
    _controller.addListener(listener);

    NativeDeviceOrientationCommunicator()
        .onOrientationChanged(useSensor: true)
        .listen((event) {
      final isPortrait = event == NativeDeviceOrientation.portraitUp;
      final isLandscape = event == NativeDeviceOrientation.landscapeLeft ||
          event == NativeDeviceOrientation.landscapeRight;
      final isTargetPortrait = target == Orientation.portrait;
      final isTargetLandscape = target == Orientation.landscape;

      if (isPortrait && isTargetPortrait || isLandscape && isTargetLandscape) {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    });
  }

  void listener() async {
    if (!mounted) return;
    //
    if (_controller.value.isInitialized) {
      var cPosition = _controller.value.position;
      var cDuration = _controller.value.duration;
      if (cDuration.inHours == 0) {
        var strPosition = cPosition.toString().split('.')[0];
        position = "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
      } else {
        position = cPosition.toString().split('.')[0];
      }
      validPosition = cDuration.compareTo(cPosition) >= 0;
      sliderValue = validPosition ? cPosition.inSeconds.toDouble() : 0;
      setState(() {});
    }
  }

  void setOrientation(bool isPortrait) {
    if (isPortrait) {
      Wakelock.disable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: SystemUiOverlay.values);
    } else {
      Wakelock.enable();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext? context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video'),
      ),
      body: FutureBuilder(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Container(
              alignment: Alignment.topCenter,
              color: Colors.black,
              child: OrientationBuilder(
                builder: (context, orientation) {
                  final isPortrait = orientation == Orientation.portrait;

                  setOrientation(isPortrait);

                  return Stack(
                      fit: isPortrait ? StackFit.loose : StackFit.expand,
                      children: <Widget>[
                        buildVideoPlayer(),
                        Positioned.fill(
                          child: AdvancedOverlayWidget(
                            controller: _controller,
                            sliderValue: sliderValue,
                            position: position,
                            validPosition: validPosition,
                            indicatorShape: indicatorShape,
                            images: images2,
                            onPositionChanged: _onSliderPositionChanged,
                            offsetChanged: (center, dragging) {
                              transX = center.dx;
                              isDragging = dragging;
                            },
                            onClickedFullScreen: () {
                              target = isPortrait
                                  ? Orientation.landscape
                                  : Orientation.portrait;

                              if (isPortrait) {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.landscapeRight,
                                  DeviceOrientation.landscapeLeft,
                                ]);
                              } else {
                                SystemChrome.setPreferredOrientations([
                                  DeviceOrientation.portraitUp,
                                  DeviceOrientation.portraitDown,
                                ]);
                              }
                            },
                          ),
                        ),
                        buildPreviewFrame(),
                      ]);
                },
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget buildVideoPlayer() {
    final video = AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller));

    return buildFullScreen(child: video);
  }

  Widget buildPreviewFrame() {
    double videoRatio = _controller.value.aspectRatio;

    double width = 0.0;

    if (target == Orientation.portrait) {
      widthScreen =
          MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
      width = widthScreen * 0.3;
    } else {
      widthScreen =
          MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
      width = widthScreen * 0.2;
    }

    double height = width / videoRatio;

    double dx;
    if ((transX + width / 2) > widthScreen) {
      dx = widthScreen - width - _overloadPadding;
    } else if ((transX - width / 2) < 0) {
      dx = _overloadPadding;
    } else {
      dx = transX - width / 2;
    }

    var frameIndex = _controller.value.position.inMinutes;

    return AnimatedOpacity(
        opacity: isDragging ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Wrap(children: [
          Transform.translate(
              offset: Offset(dx, (widthScreen / videoRatio) / 2),
              child: Column(children: [
                Container(
                    width: width,
                    height: height,
                    color: Colors.black,
                    child: (images.isNotEmpty && frameIndex <= images.length)
                        ? images[frameIndex]
                        : const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          )),
                Text(
                  position,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                )
              ]))
        ]));
  }

  Widget buildFullScreen({
    required Widget child,
  }) {
    final size = _controller.value.size;
    final width = size.width;
    final height = size.height;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(width: width, height: height, child: child),
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
