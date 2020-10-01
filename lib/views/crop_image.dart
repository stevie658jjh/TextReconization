import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../views/image_detail.dart';
import 'package:image_crop/image_crop.dart';

class CropImage extends StatefulWidget {
  String imagePath;

  CropImage(this.imagePath);

  @override
  _CropImageState createState() => new _CropImageState(imagePath);
}

class _CropImageState extends State<CropImage> {
  _CropImageState(this.imagePath);

  String imagePath;
  final cropKey = GlobalKey<CropState>();
  File _file;
  File _sample;

  @override
  void initState() {
    _file = File(imagePath);
    _sample = File(imagePath);
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _file?.delete();
    _sample?.delete();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Container(
          color: Colors.black,
          child: _buildCroppingImage(),
        ),
      ),
    );
  }

  void _showCroppingError() {
    Scaffold.of(context)
        .showSnackBar(SnackBar(content: Text("Error when cropping photo")));
  }

  Widget _buildCroppingImage() {
    return Column(
      children: <Widget>[
        Expanded(
          child: Crop.file(_sample, key: cropKey),
        ),
        Container(
          alignment: AlignmentDirectional.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              FlatButton(
                child: Text(
                  'Select area',
                  style: Theme.of(context)
                      .textTheme
                      .button
                      .copyWith(color: Colors.white),
                ),
                onPressed: () async {
                  await _cropImage().then((file) {
                    file != null
                        ? _handleCropImage(file)
                        : _showCroppingError();
                  }).catchError((onError) {
                    _showCroppingError();
                  });
                },
              ),
            ],
          ),
        )
      ],
    );
  }

  Future<File> _cropImage() async {
    final scale = cropKey.currentState.scale;
    final area = cropKey.currentState.area;
    if (area == null) {
      // cannot crop, widget is not setup
      return null;
    }

    // scale up to use maximum possible number of pixels
    // this will sample image in higher resolution to make cropped image larger
    final sample = await ImageCrop.sampleImage(
      file: _file,
      preferredSize: (2000 / scale).round(),
    );

    final file = await ImageCrop.cropImage(
      file: sample,
      area: area,
    );

    sample.delete();
    return file;
  }

  _handleCropImage(File file) async {
    var isReload = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(file.path, null),
      ),
    );
    if (isReload) Navigator.pop(context, true);
  }
}
