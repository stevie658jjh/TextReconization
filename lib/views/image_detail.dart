import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter_app/database/app_preferences.dart';
import 'package:flutter_app/model/data_models.dart';
import 'package:flutter_app/views/widget/my_icon_button.dart';
import '../view_models/images_detail_viewmodel.dart';
import '../views/widget/views_widget.dart';
import '../model/config.dart';
import 'dart:io';
import 'dart:ui';
import 'dart:async';

class DetailScreen extends StatefulWidget {
  final String imagePath;

  DetailScreen(this.imagePath);

  @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this._imagePath);

  final String _imagePath;
  List<TextElement> _elements = [];
  Size _imageSize;
  String recognizedText = "Loading ...";

  void _initializeVision() async {
    final File imageFile = File(_imagePath);

    if (imageFile != null) {
      await _getImageSize(imageFile);
    }

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromFile(imageFile);

    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();

    final VisionText visionText =
        await textRecognizer.processImage(visionImage);

    String mailAddress = "";
    for (TextBlock block in visionText.blocks) {
      for (TextLine line in block.lines) {
        mailAddress += line.text + '\n';
        _elements.addAll(line.elements);
      }
    }

    if (this.mounted) {
      setState(() {
        recognizedText = mailAddress;
      });
    }
  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    // Fetching image from path
    final Image image = Image.file(imageFile);

    // Retrieving its size
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
    });
  }

  @override
  void initState() {
    _initializeVision();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Text recognition result"),
      ),
      body: _imageSize != null
          ? Container(
              color: Colors.black87,
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Container(
                      width: double.maxFinite,
                      child: CustomPaint(
                        foregroundPainter:
                            TextDetectorPainter(_imageSize, _elements),
                        child: AspectRatio(
                          aspectRatio: _imageSize.aspectRatio,
                          child: Image.file(
                            File(_imagePath),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Card(
                      elevation: 8,
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                "Recognized text",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              height: 60,
                              child: SingleChildScrollView(
                                child: Text(
                                  recognizedText,
                                ),
                              ),
                            ),
                            FlatButton(
                                minWidth: double.infinity,
                                onPressed: () => _saveData(),
                                child: Text("Save"))
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : EmptyView(),
    );
  }

  _saveData() {
    AppPreferences()
        .setDataFile(dataFile: DataFile(_imagePath, recognizedText));
    Navigator.pop(context, true);
  }
}
