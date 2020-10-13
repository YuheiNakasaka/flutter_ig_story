library ig_story;

import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// A widget to implement behaviors like Instagram Story.
///
/// Example
/// ```dart
/// class Home extends StatefulWidget {
///   @override
///   _HomeState createState() => _HomeState();
/// }
///
/// class _HomeState extends State<Home> {
///   IgManager manager = IgManager();
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       backgroundColor: Colors.black,
///       body: IgStory(
///         children: [
///           IgChild(
///             duration: Duration(seconds: 2),
///             child: Container(
///               color: Colors.red,
///               child: Center(
///                 child: Text('first page'),
///               ),
///             ),
///           ),
///           IgChild(
///             manager: manager,
///             child: Container(
///               width: double.infinity,
///               height: double.infinity,
///               child: LoadedImage(
///                 manager: manager,
///               ),
///             ),
///           ),
///         ],
///         onCompleted: () {
///           print('All stories completed.');
///         },
///         auto: true,
///       ),
///     );
///   }
/// }
///
/// // [LoadedImage] loads image from url and
/// // calls callback(like widget.manager.play()) after finish loading.
/// class LoadedImage extends StatefulWidget {
///   final IgManager manager;
///   LoadedImage({@required this.manager});
///   State createState() => new LoadedImageState();
/// }
///
/// class LoadedImageState extends State<LoadedImage> {
///   Image _image = new Image.network(
///     'https://img.gifmagazine.net/gifmagazine/images/4407234/medium_thumb.png',
///     fit: BoxFit.cover,
///   );
///   bool _loading = true;
///
///   @override
///   void initState() {
///     super.initState();
///     _image.image
///         .resolve(ImageConfiguration())
///         .addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
///       if (mounted) {
///         widget.manager.play();
///         setState(() {
///           _loading = false;
///         });
///       }
///     }));
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return new MaterialApp(
///       home: new Scaffold(
///         backgroundColor: Colors.black,
///         body: Container(
///           width: double.infinity,
///           height: double.infinity,
///           child: _loading ? new Text('Loading...') : _image,
///         ),
///       ),
///     );
///   }
/// }
/// ```
class IgStory extends StatefulWidget {
  final List<IgChild> children;
  final bool auto;
  final VoidCallback onCompleted;
  final IgManager manager;

  IgStory({
    Key key,
    @required this.children,
    this.onCompleted,
    this.auto = true,
    this.manager,
  })  : assert(children.isEmpty),
        super(key: key);

  _IgStoryState createState() => _IgStoryState();
}

class _IgStoryState extends State<IgStory> with TickerProviderStateMixin {
  PageController _controller = PageController();
  AnimationController _animationController;
  Animation<double> _currentAnimation;
  ValueNotifier<double> _pageNotifier = ValueNotifier(0.0);
  Timer _timer;
  double _progressValue = 0.0;
  Duration _duration;
  Duration _pageSpeed = const Duration(milliseconds: 1); // almost no animation
  bool _noAnimation = false;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_listener);
      _play();
    });
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  void _listener() {
    _pageNotifier.value = _controller.page;
  }

  void _play() {
    _animationController?.dispose();

    IgChild child = widget.children[_pageNotifier.value.toInt()];

    if (_duration == null) {
      _duration = child.duration ?? Duration(seconds: 3);
    }

    _animationController =
        AnimationController(duration: _duration, vsync: this);
    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController)
          ..addListener(
            () {
              _noAnimation = false;
              setState(() {
                _progressValue = _currentAnimation.value;
              });
            },
          )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && widget.auto) {
              _next();
            }
          });

    if (child.manager != null) {
      if (!child.manager.controller.hasListener) {
        child.manager.controller.stream.listen((IgPlayState event) {
          if (event == IgPlayState.play) {
            _animationController.forward();
          }
        });
      }
    } else {
      _animationController.forward();
    }
  }

  void _next() {
    _noAnimation = true;
    if (widget.children.length - 1 > _controller.page.toInt()) {
      _duration = widget.children[_pageNotifier.value.toInt() + 1].duration ??
          Duration(seconds: 3);
      _controller.nextPage(duration: _pageSpeed, curve: Curves.linear);
    } else {
      if (widget.onCompleted != null) widget.onCompleted();
    }
  }

  void _back() {
    _noAnimation = true;
    if (_controller.page.toInt() > 0) {
      _pageNotifier.value -= 1.0;
      _duration = widget.children[_pageNotifier.value.toInt()].duration ??
          Duration(seconds: 3);
      _controller.previousPage(
        duration: _pageSpeed,
        curve: Curves.linear,
      );
    } else {
      print('No stories behind it');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pageNotifier,
      builder: (_, value, child) => Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.children.length,
            itemBuilder: (_, index) {
              return _noAnimation
                  ? widget.children[index].getWidget()
                  : CubeWidget(
                      child: widget.children[index].getWidget(),
                      index: index,
                      pageNotifier: value,
                    );
            },
            onPageChanged: (idx) {
              _progressValue = 0;
              for (int i = 0; i < widget.children.length; i++) {
                if (i < idx) {
                  widget.children[i].shown = true;
                } else {
                  widget.children[i].shown = false;
                }
              }
              _play();
            },
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Align(
                alignment: Alignment.topCenter,
                child: Row(
                  children: widget.children
                      .map(
                        (e) => Expanded(
                          child: Container(
                            padding: EdgeInsets.only(right: 1),
                            child: StoryProgressIndicator(
                              widget.children[value.toInt()].getWidget().key ==
                                      e.getWidget().key
                                  ? widget.children[value.toInt()].shown
                                      ? 1
                                      : _progressValue
                                  : e.shown
                                      ? 1
                                      : 0,
                              indicatorHeight: 3,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            heightFactor: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: GestureDetector(
                onTap: () {
                  _next();
                },
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            heightFactor: 1,
            child: SizedBox(
              width: MediaQuery.of(context).size.width / 2,
              child: GestureDetector(
                onTap: () {
                  _back();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IgChild {
  final Widget child;
  final Duration duration;
  final IgManager manager;

  bool shown = false;

  IgChild({@required child, this.duration, this.manager})
      : this.child = SizedBox(
          key: UniqueKey(),
          child: child,
        );

  Widget getWidget() {
    return child;
  }
}

enum IgPlayState { play, pause, stop }

class IgManager {
  final StreamController<IgPlayState> controller;
  IgManager() : this.controller = StreamController<IgPlayState>();

  void play() {
    controller.sink.add(IgPlayState.play);
  }

  void pause() {
    controller.sink.add(IgPlayState.pause);
  }

  void stop() {
    controller.sink.add(IgPlayState.stop);
  }
}

// Refs: https://github.com/aeyrium/cube_transition
num degToRad(num deg) => deg * (pi / 180.0);
num radToDeg(num rad) => rad * (180.0 / pi);

class CubeWidget extends StatelessWidget {
  final int index;

  final double pageNotifier;

  final Widget child;

  const CubeWidget({
    Key key,
    @required this.index,
    @required this.pageNotifier,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLeaving = (index - pageNotifier) <= 0;
    final t = (index - pageNotifier);
    final rotationY = lerpDouble(0, 45, t);
    final opacity = lerpDouble(0, 1, t.abs()).clamp(0.0, 1.0);
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.003);
    transform.rotateY(-degToRad(rotationY));
    return Transform(
      alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
      transform: transform,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: Opacity(
              opacity: opacity,
              child: Container(
                child: Container(
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Refs: https://github.com/blackmann/story_view
class StoryProgressIndicator extends StatelessWidget {
  final double value;
  final double indicatorHeight;

  StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
  }) : assert(indicatorHeight != null && indicatorHeight > 0,
            "[indicatorHeight] should not be null or less than 1");

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        this.indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        Colors.white.withOpacity(0.8),
        this.value,
      ),
      painter: IndicatorOval(
        Colors.white.withOpacity(0.4),
        1.0,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  final Color color;
  final double widthFactor;

  IndicatorOval(this.color, this.widthFactor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = this.color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width * this.widthFactor, size.height),
            Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
