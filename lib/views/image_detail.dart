import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'dart:io' show Platform;

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:directory_picker/directory_picker.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/database/app_preferences.dart';
import 'package:flutter_app/model/config.dart';
import 'package:flutter_app/model/data_models.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../view_models/images_detail_viewmodel.dart';
import '../views/widget/views_widget.dart';
import 'home/home_page.dart';

class DetailScreen extends StatefulWidget {
  final String imagePath;
  final DataFile isEditMode;

  DetailScreen(this.imagePath, this.isEditMode);

  @override
  _DetailScreenState createState() =>
      new _DetailScreenState(imagePath, isEditMode);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this._imagePath, this._dataFile);

  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final String _imagePath;
  final DataFile _dataFile;

  List<TextElement> _elements = [];
  Size _imageSize;
  String recognizedText = "Loading ...";

  void _initializeVision() async {
    String currentTextDetected = "";
    final File imageFile = File(_imagePath);
    if (imageFile != null) {
      await _getImageSize(imageFile);
    }
    if (_dataFile != null) {
      currentTextDetected = _dataFile.textDetected;
    } else {
      final FirebaseVisionImage visionImage =
          FirebaseVisionImage.fromFile(imageFile);

      final TextRecognizer textRecognizer =
          FirebaseVision.instance.textRecognizer();

      final VisionText visionText =
          await textRecognizer.processImage(visionImage);
      for (TextBlock block in visionText.blocks) {
        for (TextLine line in block.lines) {
          currentTextDetected += line.text + '\n';
          _elements.addAll(line.elements);
        }
      }
    }

    if (this.mounted) {
      setState(() {
        recognizedText = currentTextDetected;
        if (_dataFile == null) {
          saveData();
        }
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
      key: _scaffoldKey,
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
                            _actionView()
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

  _actionView() => Row(
        children: [
          myButton.expandedIconButton(
              icon: Icons.picture_as_pdf,
              text: "To PDF",
              function: () => {getPdf()}),
          myButton.expandedIconButton(
              icon: Icons.text_snippet,
              text: "Copy text",
              function: () => {copyToClipBoard()}),
          myButton.expandedIconButton(
              icon: Icons.close, text: "Close", function: () => {_exit()}),
        ],
      );

  saveData() {
    AppPreferences()
        .setDataFile(dataFile: DataFile(_imagePath, recognizedText));
  }

  _savePdf(pw.Document pdf) async {
    _dismissDialog();
    Directory appDocDir;
    if (Platform.isAndroid) {
      appDocDir = await getExternalStorageDirectory();
    } else if (Platform.isIOS) {
      appDocDir = await getDownloadsDirectory();
    }
    Directory newDirectory =
        await DirectoryPicker.pick(context: context, rootDirectory: appDocDir);
    print(newDirectory.path);

    var name = await AppUtil.getFileNameWithExtension(File(_imagePath));
    final file = File("${newDirectory.path}/$name.pdf");
    await file
        .writeAsBytes(pdf.save())
        .then((fileSaved) => _showPdfSaveDone(fileSaved));
  }

  _dismissDialog() => Navigator.of(context, rootNavigator: true).pop("Discard");

  getPdf() async {
    final pdf = pw.Document();
    var image = await pdfImageFromImageProvider(
      pdf: pdf.document,
      image: FileImage(File(_imagePath)),
    );
    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(
        child: pw.Image(image),
      ); // Center
    }));
    _showPdfProgress(pdf);
  }

  previewPDF(pw.Document pdf) {
    _dismissDialog();
    var preview = PdfPreview(build: (format) => pdf.save());
    Navigator.push(context, MaterialPageRoute(builder: (context) => preview));
  }

  copyToClipBoard() {
    ClipboardManager.copyToClipBoard(recognizedText).then((result) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Copied to Clipboard'),
      ));
    });
  }

  Future<void> _showPdfProgress(pw.Document pdf) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Container(
              padding: EdgeInsets.all(10),
              child: Image.asset("assets/images/success.png",
                  width: 50, height: 50)),
          content: Text('PDF Convert done!'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Preview'),
              onPressed: () => previewPDF(pdf),
            ),
            CupertinoDialogAction(
              child: Text('Save PDF'),
              onPressed: () => _savePdf(pdf),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPdfSaveDone(File file) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('PDF Converter'),
          content: Text("File is saved successfully!"),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text('Open'),
              onPressed: () => openPdfFile(file),
            ),
            CupertinoDialogAction(
              child: Text('Close'),
              onPressed: () => _dismissDialog(),
            ),
          ],
        );
      },
    );
  }

  openPdfFile(File file) async {
    var a = await OpenFile.open(file.path);
    print(a);
  }

  _exit() => Navigator.pop(context, true);
}
