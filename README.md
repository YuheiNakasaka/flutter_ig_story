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
![12850023488720_2](https://user-images.githubusercontent.com/1421093/95946303-3c1d5200-0e27-11eb-8480-407d8a3055c9.gif)

1. Define `IgManager` to control the story's animation.
2. Create widgets which you want to display.
3. Wrap each of them with `IgChild`.
4. Pass the IgChilds to `IgStory`. That's it.

### Example

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
        manager: manager,
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
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: MyImageLoader(
                manager: manager,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example image loader widget.
// it's not this library's widget.
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

## Advanced
![12850023488720](https://user-images.githubusercontent.com/1421093/95945503-94ebeb00-0e25-11eb-8b79-ded79d99c1c7.gif)

You can use `IgStories` which is the wrapper to wrap up `IgStory` widgets. The `IgStory` widget wrapped `IgStories` is animated to next `IgStory` widget smoothly like Instagram's cube transition.

### Example

```dart
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  IgManager manager = IgManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IgStories(
        manager: manager,
        children: [
          // User A's Story
          IgStory(
            manager: manager,
            children: [
              IgChild(
                child: Container(
                  color: Colors.red,
                  child: Center(
                    child: Text(
                      'first page',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              IgChild(
                duration: Duration(seconds: 2),
                child: Container(
                  color: Colors.green,
                  child: Center(
                    child: Text(
                      'second page',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              IgChild(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: LoadedImage(
                    manager: manager,
                    url:
                        "https://img.gifmagazine.net/gifmagazine/images/4407234/medium_thumb.png",
                  ),
                ),
              ),
            ],
          ),
          // User B's Story
          IgStory(
            manager: manager,
            children: [
              IgChild(
                child: Container(
                  color: Colors.blue,
                  child: Center(
                    child: Text(
                      'first page',
                      style:
                          TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              IgChild(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: LoadedImage(
                    manager: manager,
                    url:
                        "https://img.gifmagazine.net/gifmagazine/images/4381451/medium_thumb.png",
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    manager.controller.close();
    super.dispose();
  }
}

class LoadedImage extends StatefulWidget {
  final String url;
  final IgManager manager;
  LoadedImage({@required this.manager, @required this.url});
  State createState() => new LoadedImageState();
}

class LoadedImageState extends State<LoadedImage> {
  Image _image;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _image = Image.network(
      widget.url,
      fit: BoxFit.cover,
    );
    _image.image
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool syncCall) {
      if (mounted) {
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
