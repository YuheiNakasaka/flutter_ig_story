import 'package:flutter/material.dart';
import 'package:ig_story/ig_story.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Story Demo',
      theme: ThemeData(
        primaryColor: Colors.green,
      ),
      home: Home(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
      body: IgStory(
        manager: manager,
        children: [
          IgChild(
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
            duration: Duration(seconds: 2),
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
          IgChild(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: LoadedImage(
                manager: manager,
              ),
            ),
          ),
        ],
        auto: true,
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
  final IgManager manager;
  LoadedImage({@required this.manager});
  State createState() => new LoadedImageState();
}

class LoadedImageState extends State<LoadedImage> {
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
          child: _loading ? Center(child: Text('Loading...')) : _image,
        ),
      ),
    );
  }
}
