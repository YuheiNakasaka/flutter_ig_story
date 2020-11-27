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
///         manager: manager,
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
  IgStory({
    Key key,
    @required this.children,
    @required this.manager,
    this.auto = true,
    this.enablelLeftBack = true,
    this.enablelRightNext = true,
    this.showProgressBar = true,
  })  : assert(children.isNotEmpty),
        super(key: key);

  final List<IgChild> children;
  final IgManager manager;
  final bool auto;
  final bool enablelLeftBack;
  final bool enablelRightNext;
  final bool showProgressBar;

  @override
  _IgStoryState createState() => _IgStoryState();
}

class _IgStoryState extends State<IgStory> with TickerProviderStateMixin {
  final PageController _controller = PageController();
  AnimationController _animationController;
  Animation<double> _currentAnimation;
  final ValueNotifier<double> _pageNotifier = ValueNotifier(0.0);
  double _progressValue = 0.0;
  Duration _duration;
  // almost no animation
  final Duration _pageSpeed = const Duration(milliseconds: 1);

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

    final child = widget.children[_pageNotifier.value.toInt()];

    _duration = child.duration ?? const Duration(seconds: 6);

    _animationController =
        AnimationController(duration: _duration, vsync: this);
    _currentAnimation =
        Tween(begin: 0.0, end: 1.0).animate(_animationController)
          ..addListener(
            () {
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

    widget.manager.controller.stream.listen((IgPlayState event) {
      switch (event) {
        case IgPlayState.play:
          if (!_animationController
                  .toStringDetails()
                  .contains(RegExp(r'DISPOSED')) &&
              !_animationController.isAnimating) {
            _animationController.forward();
          }
          break;
        case IgPlayState.pageChanged:
          for (var i = 0; i < widget.children.length; i++) {
            widget.children[i].shown = false;
          }
          break;
        case IgPlayState.pause:
          if (!_animationController
                  .toStringDetails()
                  .contains(RegExp(r'DISPOSED')) &&
              _animationController.isAnimating) {
            _animationController.stop();
          }
          break;
        default:
      }
    });
    widget.manager.controller.sink.add(IgPlayState.play);
  }

  void _next() {
    if (widget.children.length - 1 > _controller.page.toInt()) {
      _duration = widget.children[_pageNotifier.value.toInt() + 1].duration ??
          const Duration(seconds: 3);
      _controller.nextPage(
        duration: _pageSpeed,
        curve: Curves.linear,
      );
    } else {
      widget.manager.controller.sink.add(IgPlayState.next);
    }
  }

  void _back() {
    if (_controller.page.toInt() > 0) {
      _pageNotifier.value -= 1.0;
      _duration = widget.children[_pageNotifier.value.toInt()].duration ??
          const Duration(seconds: 3);
      _controller.previousPage(
        duration: _pageSpeed,
        curve: Curves.linear,
      );
    } else {
      widget.manager.controller.sink.add(IgPlayState.back);
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
              return widget.children[index].getWidget();
            },
            onPageChanged: (idx) {
              _progressValue = 0;
              for (var i = 0; i < widget.children.length; i++) {
                if (i < idx) {
                  widget.children[i].shown = true;
                } else {
                  widget.children[i].shown = false;
                }
              }
              _play();
            },
            physics: const NeverScrollableScrollPhysics(),
          ),
          widget.showProgressBar
              ? SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 10, left: 10, right: 10),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Row(
                        children: widget.children
                            .map(
                              (e) => Expanded(
                                child: Container(
                                  padding: const EdgeInsets.only(right: 1),
                                  child: StoryProgressIndicator(
                                    widget.children[value.toInt()]
                                                .getWidget()
                                                .key ==
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
                )
              : const SizedBox(height: 0),
          widget.enablelLeftBack
              ? Align(
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
                )
              : const SizedBox(height: 0),
          widget.enablelRightNext
              ? Align(
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
                )
              : const SizedBox(height: 0),
          widget.children[value.toInt()].layerWidget ??
              const SizedBox(height: 0),
        ],
      ),
    );
  }
}

/// IgStory wrapper
///
/// ```dart
/// class Home extends StatefulWidget {
///   @override
///   _HomeState createState() => _HomeState();
/// }
/// class _HomeState extends State<Home> {
///   IgManager manager = IgManager();
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       backgroundColor: Colors.black,
///       body: IgStories(
///         manager: manager,
///         children: [
///           IgStory(
///             manager: manager,
///             children: [
///               IgChild(
///                 child: Container(
///                   color: Colors.red,
///                   child: Center(
///                     child: Text(
///                       'first page',
///                       style:
///                           TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
///                     ),
///                   ),
///                 ),
///               ),
///               IgChild(
///                 duration: Duration(seconds: 2),
///                 child: Container(
///                   color: Colors.green,
///                   child: Center(
///                     child: Text(
///                       'second page',
///                       style:
///                           TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
///                     ),
///                   ),
///                 ),
///               ),
///               IgChild(
///                 child: Container(
///                   width: double.infinity,
///                   height: double.infinity,
///                   child: LoadedImage(
///                     manager: manager,
///                     url:
///                         "https://img.gifmagazine.net/gifmagazine/images/4407234/medium_thumb.png",
///                   ),
///                 ),
///               ),
///             ],
///           ),
///           IgStory(
///             manager: manager,
///             children: [
///               IgChild(
///                 child: Container(
///                   color: Colors.blue,
///                   child: Center(
///                     child: Text(
///                       'first page',
///                       style:
///                           TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
///                     ),
///                   ),
///                 ),
///               ),
///               IgChild(
///                 child: Container(
///                   width: double.infinity,
///                   height: double.infinity,
///                   child: LoadedImage(
///                     manager: manager,
///                     url:
///                         "https://img.gifmagazine.net/gifmagazine/images/4381451/medium_thumb.png",
///                   ),
///                 ),
///               ),
///             ],
///           )
///         ],
///       ),
///     );
///   }
///   @override
///   void dispose() {
///     manager.controller.close();
///     super.dispose();
///   }
/// }
/// ```
class IgStories extends StatefulWidget {
  IgStories({
    Key key,
    @required this.children,
    @required this.manager,
    this.startIndex = 0,
  })  : assert(children.isNotEmpty),
        super(key: key);

  final List<IgStory> children;
  final IgManager manager;
  final double startIndex;

  @override
  _IgStoriesState createState() => _IgStoriesState();
}

class _IgStoriesState extends State<IgStories> {
  PageController _controller;
  ValueNotifier<double> _pageNotifier;

  @override
  void initState() {
    super.initState();
    _controller = PageController(initialPage: widget.startIndex.toInt());
    _pageNotifier = ValueNotifier(widget.startIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.addListener(_listener);
    });
    if (widget.manager != null) {
      if (!widget.manager.controller.hasListener) {
        widget.manager.controller.stream.listen((IgPlayState event) {
          switch (event) {
            case IgPlayState.next:
              _controller.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
              break;
            case IgPlayState.back:
              _controller.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
              break;
            default:
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_listener);
    _controller.dispose();
    super.dispose();
  }

  void _listener() {
    _pageNotifier.value = _controller.page;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _pageNotifier,
      builder: (_, value, child) => Container(
        child: PageView.builder(
          controller: _controller,
          itemCount: widget.children.length,
          itemBuilder: (_, index) {
            return CubeWidget(
              child: widget.children[index],
              index: index,
              pageNotifier: value,
            );
          },
          onPageChanged: (e) {
            widget.manager.controller.sink.add(IgPlayState.pageChanged);
          },
        ),
      ),
    );
  }
}

enum IgPlayState {
  play,
  pause,
  stop,
  next,
  back,
  pageChanged,
}

class IgManager {
  IgManager() : controller = StreamController<IgPlayState>.broadcast();

  final StreamController<IgPlayState> controller;

  void play() {
    controller.sink.add(IgPlayState.play);
  }

  void pause() {
    controller.sink.add(IgPlayState.pause);
  }

  void stop() {
    controller.sink.add(IgPlayState.stop);
  }

  void next() {
    controller.sink.add(IgPlayState.next);
  }

  void back() {
    controller.sink.add(IgPlayState.back);
  }

  void pageChanged() {
    controller.sink.add(IgPlayState.pageChanged);
  }
}

class IgChild {
  IgChild({
    @required Widget child,
    this.duration,
    this.layerWidget,
  }) : child = SizedBox(
          key: UniqueKey(),
          child: child,
        );

  final Widget child;
  final Duration duration;
  final Widget layerWidget;

  bool shown = false;

  Widget getWidget() {
    return child;
  }
}

// Refs: https://github.com/aeyrium/cube_transition
num degToRad(num deg) => deg * (pi / 180.0);
num radToDeg(num rad) => rad * (180.0 / pi);

class CubeWidget extends StatelessWidget {
  const CubeWidget({
    Key key,
    @required this.index,
    @required this.pageNotifier,
    @required this.child,
  }) : super(key: key);

  final int index;

  final double pageNotifier;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLeaving = (index - pageNotifier) < 0;
    final t = index - pageNotifier;
    final rotationY = lerpDouble(0, 45, t);
    final opacity = lerpDouble(0, 1, t.abs()).clamp(0.0, 1.0).toDouble();
    final transform = Matrix4.identity();
    transform.setEntry(3, 2, 0.003);
    transform.rotateY(-degToRad(rotationY).toDouble());
    return Transform(
      alignment: isLeaving ? Alignment.centerRight : Alignment.centerLeft,
      transform: transform,
      child: Stack(
        // Without this condition,
        // child's onTap() can't be called.
        children: isLeaving
            ? [
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
              ]
            : [child],
      ),
    );
  }
}

// Refs: https://github.com/blackmann/story_view
class StoryProgressIndicator extends StatelessWidget {
  const StoryProgressIndicator(
    this.value, {
    this.indicatorHeight = 5,
  }) : assert(indicatorHeight != null && indicatorHeight > 0,
            '[indicatorHeight] should not be null or less than 1');

  final double value;
  final double indicatorHeight;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.fromHeight(
        indicatorHeight,
      ),
      foregroundPainter: IndicatorOval(
        Colors.white.withOpacity(0.8),
        value,
      ),
      painter: IndicatorOval(
        Colors.white.withOpacity(0.4),
        1,
      ),
    );
  }
}

class IndicatorOval extends CustomPainter {
  IndicatorOval(this.color, this.widthFactor);

  final Color color;
  final double widthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width * widthFactor, size.height),
            const Radius.circular(3)),
        paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
