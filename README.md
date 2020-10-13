# ig_story

A player widget to implement Stories like Instagram.

# Installation

To use this plugin, add `ig_story` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

# Usage
Import the package into your code

```dart
import "package:ig_story/ig_story.dart";
```

## Basics
1. Create widgets which you want to display.
2. Wrap each of them with `IgChild`.
3. Pass the IgChilds to `IgStory`. That's it.

## Advanced
If you display something which takes long time to load like image and video,
you need to use `IgManager` to control the story's animation. In detail, see the below example.

# Example

```dart
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Manager to control animation.
  IgManager manager = IgManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IgStory(
        children: [
          // Basic Widget
          IgChild(
            // Optional
            duration: Duration(seconds: 2),
            // Required: Any widget can be set.
            child: Container(
              color: Colors.red,
              child: Center(
                child: Text(
                  'first page',
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          IgChild(
            child: Container(
              color: Colors.green,
              child: Center(
                child: Text(
                  'second page',
                  style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          // Advanced usage
          // After finished loading, trigger story animations.
          IgChild(
            manager: manager,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: MyImageLoader(
                manager: manager,
              ),
            ),
          ),
        ],
        onCompleted: () {
          print('All stories completed.');
        },
        auto: true, // Optional. Default: true.
      ),
    );
  }
}

class MyImageLoader extends StatefulWidget {
  final IgManager manager;
  MyImageLoader({@required this.manager});
  State createState() => new MyImageLoaderState();
}

class MyImageLoaderState extends State<MyImageLoader> {
  Image _image = new Image.network(
    'https://img.gifmagazine.net/gifmagazine/images/4407234/original.gif',
    fit: BoxFit.cover,
  );
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _image.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
      if (mounted) {
        // Calls play() method after finished loading all image data.
        widget.manager.play();
        setState(() {
          _loading = false;
        });
      }
    }));
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        backgroundColor: Colors.black,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          child: _loading ? new Text('Loading...') : _image,
        ),
      ),
    );
  }
}
```

