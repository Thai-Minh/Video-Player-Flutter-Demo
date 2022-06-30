import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_device_orientation/native_device_orientation.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'advanced_overlay_widget.dart';
import 'custom/player_path_painter.dart';

const double videoRatio = 16 / 9;

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

  bool isDragging = false;

  Offset centerValue = Offset(0.0, 0.0);

  ui.Image? customImage1;

  PlayerIndicatorShape indicatorShape = const PlayerIndicatorShape();

  Orientation? target;

  var widgetKey = GlobalKey();

  @override
  void initState() {
    load('assets/images/ratio169.png').then((image) {
      setState(() {
        customImage1 = image;
      });
    });

    super.initState();

    _controller = VideoPlayerController.network(
        "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd");

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
        target = null;
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
                        buildPreviewFrame(context),
                        Positioned.fill(
                          child: AdvancedOverlayWidget(
                            controller: _controller,
                            sliderValue: sliderValue,
                            position: position,
                            validPosition: validPosition,
                            indicatorShape: indicatorShape,
                            image: customImage1,
                            onPositionChanged: _onSliderPositionChanged,
                            onOffsetChanged: (center) {
                              if (isDragging) {
                                centerValue = center;
                              } else {
                                centerValue = Offset.zero;
                              }
                            },
                            onDragging: (dragging) {
                              isDragging = dragging;
                              if (!dragging) {
                                centerValue = Offset.zero;
                              }
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

  Widget buildPreviewFrame(BuildContext context) {
    var width = MediaQuery.of(context).size.width * 0.3;
    var height = width / videoRatio;

    print("MTHAI: centerValue: $centerValue");
    return Container(
      width: width,
      height: height,
      child: Transform.translate(
          offset: centerValue,
          child: centerValue != Offset.zero
              ? Container(
                  color: Colors.black,
                  child: Image.asset('assets/images/dog.png'))
              : Container()),
    );
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

  Future<ui.Image> load(String asset) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }
}
