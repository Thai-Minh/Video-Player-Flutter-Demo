import 'package:flutter/material.dart';
import 'package:helloworld/preview_loader.dart';
import 'package:helloworld/utils.dart';
import 'package:video_player/video_player.dart' as player;

import 'old/player_indicator_shape.dart';

const double _previewOverloadPadding = 10;
const double _videoRatio = 16 / 9;

enum ControllerAction { next, previous, play }

class VideoPlayer extends StatefulWidget {
  const VideoPlayer({Key? key}) : super(key: key);

  @override
  State<VideoPlayer> createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  late player.VideoPlayerController _controller;

  int get duration => _controller.value.duration.inMilliseconds;

  int get position => _controller.value.position.inMilliseconds;

  String get strPosition =>
      Utils().formatTimeToString(_controller.value.position.inMilliseconds);

  Orientation target = Orientation.portrait;
  double widthScreen = 0.0;

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

    if (target == Orientation.portrait) {
      widthScreen =
          MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
      setState(() => {});
    } else {
      widthScreen =
          MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
      setState(() => {});
    }
  }

  void listener() {
    setState(() => {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: _controller.value.isInitialized
          ? Stack(
              children: [
                _Player(controller: _controller),
                _CenterController(
                  isPlaying: _controller.value.isPlaying,
                  onPositionChanged: _onControllerClicked,
                ),
                _PreviewController(
                  widthScreen: widthScreen,
                  position: position,
                  duration: duration,
                  strPosition: strPosition,
                  onPositionChanged: _onPositionChanged,
                  onChangeEnd: () {
                    setState(() {});
                  },
                  onRotateClicked: () {},
                )
              ],
            )
          : AspectRatio(
              aspectRatio: _videoRatio,
              child: Container(
                color: Colors.black,
                child: const Center(
                    child: CircularProgressIndicator(
                  color: Colors.white,
                )),
              ),
            ),
    );
  }

  void _onControllerClicked(ControllerAction action) {
    switch (action) {
      case ControllerAction.play:
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
        break;
      case ControllerAction.next:
        if (position < duration) {
          _controller.seekTo(Duration(milliseconds: position + 5000));
        } else {
          _controller.seekTo(_controller.value.duration);
        }
        break;
      case ControllerAction.previous:
        if (position > 5000) {
          _controller.seekTo(Duration(milliseconds: position - 5000));
        } else {
          _controller.seekTo(const Duration(seconds: 0));
        }
        break;
    }
    setState(() {});
  }

  void _onPositionChanged(double progress) {
    _setTime(progress.floor().toInt());
    setState(() {});
  }

  Future<void> _setTime(int time) async {
    return await _controller.seekTo(Duration(milliseconds: time));
  }
}

class _PreviewController extends StatefulWidget {
  const _PreviewController({
    Key? key,
    required this.widthScreen,
    required this.position,
    required this.duration,
    required this.strPosition,
    required this.onPositionChanged,
    required this.onChangeEnd,
    required this.onRotateClicked,
  }) : super(key: key);

  final double widthScreen;
  final int position;
  final int duration;

  final String strPosition;

  final ValueChanged<double> onPositionChanged;
  final VoidCallback onChangeEnd;
  final VoidCallback onRotateClicked;

  @override
  State<_PreviewController> createState() => _PreviewControllerState();
}

class _PreviewControllerState extends State<_PreviewController> {
  double sliderPosition = 0.0;
  bool isShow = false;
  double offsetX = 0.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          IgnorePointer(ignoring: true, child: buildOverlay()),
          Row(
            children: [
              const SizedBox(width: 8),
              Expanded(child: buildSlider(context)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onRotateClicked,
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
    );
  }

  Widget buildOverlay() {
    double width = widget.widthScreen * 0.3;
    double height = width / _videoRatio;

    double dx;
    if ((offsetX + width / 2) > widget.widthScreen) {
      dx = widget.widthScreen - width - _previewOverloadPadding;
    } else if ((offsetX - width / 2) < 0) {
      dx = _previewOverloadPadding;
    } else {
      dx = offsetX - width / 2 + _previewOverloadPadding;
    }

    return FutureBuilder<Image>(
        future: PreviewLoader.loadImage(widget.position),
        builder: (context, snapshot) {
          final image = snapshot.data;
          return AnimatedOpacity(
              opacity: isShow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Flexible(
                child: Transform.translate(
                  offset: Offset(dx, 0.0),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      children: [
                        Column(
                          children: [
                            buildPreview(image, width, height),
                            const SizedBox(height: 6),
                            buildTime(),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ));
        });
  }

  Widget buildSlider(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackShape: const RectangularSliderTrackShape(),
        activeTrackColor: Colors.blue[700],
        inactiveTrackColor: Colors.blue[100],
        trackHeight: 4.0,
        thumbShape: SliderComponentShape.noOverlay,
        thumbColor: Colors.blueAccent,
        overlayColor: Colors.blueAccent,
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 6.0),
        tickMarkShape: const RoundSliderTickMarkShape(),
        activeTickMarkColor: Colors.blue[700],
        inactiveTickMarkColor: Colors.blue[100],
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
        ),
      ),
      child: SizedBox(
          height: 40,
          child: PlayerSlider(
            value: isShow ? sliderPosition : widget.position.toDouble(),
            min: 0.0,
            max: widget.duration.toDouble(),
            divisions: widget.duration > 0 ? widget.duration ~/ 1000 : 1,
            onChanged: (value) {
              setState(() => {
                    sliderPosition = value,
                  });
            },
            onChangeStart: (_) {
              isShow = true;
            },
            onChangeEnd: (_) {
              isShow = false;
              setState(() => {});
              widget.onChangeEnd;
              widget.onPositionChanged(sliderPosition);
            },
            onOffsetChanged: (center, isDragging) {
              offsetX = center.dx;
            },
          )),
    );
  }

  Widget buildPreview(Image? image, double width, double height) {
    return Container(
      color: Colors.grey,
      width: width,
      height: height,
      child: image,
    );
  }

  Widget buildTime() {
    return Text(
      isShow
          ? Utils().formatTimeToString(sliderPosition.toInt())
          : widget.strPosition,
      maxLines: 1,
      style: const TextStyle(color: Colors.white),
    );
  }
}

class _CenterController extends StatelessWidget {
  final bool isPlaying;
  final ValueChanged<ControllerAction> onPositionChanged;

  const _CenterController(
      {Key? key, required this.onPositionChanged, required this.isPlaying})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isPlaying ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AspectRatio(
        aspectRatio: _videoRatio,
        child: Container(
          color: Colors.black26,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildPlayerIcon(ControllerAction.previous, Icons.skip_previous,
                    30, onPositionChanged),
                const SizedBox(width: 30),
                buildPlayerIcon(
                    ControllerAction.play,
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    60,
                    onPositionChanged),
                const SizedBox(width: 30),
                buildPlayerIcon(ControllerAction.next, Icons.skip_next, 30,
                    onPositionChanged),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPlayerIcon(ControllerAction action, IconData icon, double size,
      ValueChanged<ControllerAction> onPositionChanged) {
    return InkWell(
      onTap: () {
        onPositionChanged(action);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }
}

class _Player extends StatelessWidget {
  final player.VideoPlayerController controller;

  const _Player({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: _videoRatio,
      child: player.VideoPlayer(controller),
    );
  }
}
