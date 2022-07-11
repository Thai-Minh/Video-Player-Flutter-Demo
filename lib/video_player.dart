import 'package:flutter/material.dart';
import 'package:helloworld/custom_preview.dart';
import 'package:helloworld/preview_loader.dart';
import 'package:helloworld/utils.dart';
import 'package:video_player/video_player.dart' as player;

import 'custom_progressbar.dart';
import 'main.dart';

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

  int get buffer {
    var list = _controller.value.buffered;

    if (list.isNotEmpty) {
      return list.first.end.inMilliseconds;
    } else {
      return 0;
    }
  }

  String get strPosition => Utils().getTimeString(_controller.value.position);

  Orientation target = Orientation.portrait;
  double widthScreen = 0.0;

  @override
  void initState() {
    super.initState();

    // _controller = player.VideoPlayerController.network(
    //   "https://bitmovin-a.akamaihd.net/content/MI201109210084_1/mpds/f08e80da-bf1d-4e3d-8899-f0f6155f6efa.mpd",
    //   videoPlayerOptions: player.VideoPlayerOptions(
    //     allowBackgroundPlayback: true,
    //   ),
    // )..initialize().then((value) => setState(() => {}));

    var parentPlayerData = ParentPlayerData.of(context);

    if(parentPlayerData != null) {
      _controller = parentPlayerData.controller;
    }

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
                  buffer: buffer,
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

  void _onPositionChanged(int progress) {
    _setTime(progress.floor());
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
    required this.buffer,
    required this.strPosition,
    required this.onPositionChanged,
    required this.onChangeEnd,
    required this.onRotateClicked,
  }) : super(key: key);

  final double widthScreen;
  final int position;
  final int duration;
  final int buffer;

  final String strPosition;

  final ValueChanged<int> onPositionChanged;
  final VoidCallback onChangeEnd;
  final VoidCallback onRotateClicked;

  @override
  State<_PreviewController> createState() => _PreviewControllerState();
}

class _PreviewControllerState extends State<_PreviewController>
    with SingleTickerProviderStateMixin {
  int _sliderPosition = 0;
  bool _isShow = false;

  late AnimationController _animController;

  @override
  void initState() {
    _animController = AnimationController(
        duration: const Duration(milliseconds: 350), vsync: this);

    super.initState();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Column(
        children: [
          IgnorePointer(ignoring: true, child: buildOverlay()),
          Column(
            children: [
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: widget.onRotateClicked,
                  child: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              buildSeekbar(context),
            ],
          )
        ],
      ),
    );
  }

  Widget buildOverlay() {
    return FutureBuilder<Image>(
        future: PreviewLoader.loadImage(widget.position),
        builder: (context, snapshot) {
          final image = snapshot.data;
          return AnimatedOpacity(
              opacity: _isShow ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Flexible(
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: ProgressPreview(
                    progress: _sliderPosition / widget.duration,
                    child: Column(
                      children: [
                        buildPreview(image),
                        const SizedBox(height: 6),
                        buildTime(),
                      ],
                    ),
                  ),
                ),
              ));
        });
  }

  Widget buildSeekbar(BuildContext context) {
    var progress = _isShow
        ? Duration(milliseconds: _sliderPosition.toInt())
        : Duration(milliseconds: widget.position);

    return ProgressBar(
      animController: _animController,
      progress: progress,
      total: Duration(milliseconds: widget.duration),
      buffered: Duration(milliseconds: widget.buffer),
      backgroundBarColor: Colors.white.withOpacity(0.24),
      progressBarColor: Colors.red,
      bufferedBarColor: Colors.white.withOpacity(0.24),
      thumbBlurColor: Colors.red,
      thumbColor: Colors.red,
      onDragStart: (_) {
        _isShow = true;
      },
      onDragUpdate: (duration) {
        setState(() => {
              _sliderPosition = duration.inMilliseconds,
            });
      },
      onSeek: (duration) {
        _isShow = false;
        setState(() => {_sliderPosition = duration.inMilliseconds});
        widget.onChangeEnd;
        widget.onPositionChanged(_sliderPosition);
      },
    );
  }

  Widget buildPreview(Image? image) {
    var width = widget.widthScreen * 0.4;
    return Container(
      color: Colors.black,
      width: width,
      height: width / _videoRatio,
      child: image,
    );
  }

  Widget buildTime() {
    return Text(
      _isShow
          ? Utils()
              .getTimeString(Duration(milliseconds: _sliderPosition.toInt()))
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
