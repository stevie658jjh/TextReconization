import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/database/app_preferences.dart';
import 'package:flutter_app/model/data_models.dart';
import 'package:flutter_app/views/crop_image.dart';
import 'package:flutter_app/views/widget/my_icon_button.dart';
import 'package:image_picker/image_picker.dart';

import '../image_detail.dart';

var myButton = MyIconButton();

class HomePage extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<HomePage> {
  List<DataFile> dataList;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  _reloadData() async {
    var data = await AppPreferences().getListDataFile();
    setState(() {
      dataList = data;
      print("Data xx ${dataList.length}");
    });
  }

  @override
  void initState() {
    _reloadData();
    super.initState();
  }

  @override
  void dispose() {
    dataList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFECEFF1),
      appBar: appBar(),
      body: SafeArea(
        child: Column(children: <Widget>[
          SizedBox(height: 5),
          _topAction(),
          SizedBox(height: 5),
          _mainBody(),
        ]),
      ),
    );
  }

  openCropImage(PickedFile pickedFile) async {
    var isReload = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => CropImage(pickedFile.path)));
    if (isReload == true) _reloadData();
  }

  _getImage(ImageSource imageSource) async {
    final pickedFile = await ImagePicker().getImage(source: imageSource);
    pickedFile != null ? openCropImage(pickedFile) : takeImageFailed();
    return pickedFile.path;
  }

  takeImageFailed() => _scaffoldKey.currentState.showSnackBar(SnackBar(content: Text("Please select image")));

  appBar() => AppBar(
        title: Text("Home"),
        actions: [
          IconButton(
              onPressed: () async {
                _getImage(ImageSource.camera);
              },
              icon: Icon(Icons.camera_alt)),
          IconButton(
              onPressed: () async {
                _getImage(ImageSource.gallery);
              },
              icon: Icon(Icons.photo))
        ],
      );

  _topAction() => Row(
        children: [
          myButton.expandedIconButton(
              icon: Icons.picture_as_pdf,
              text: "PDF tools",
              function: () => {takeImageFailed()}),
          myButton.expandedIconButton(
              icon: Icons.text_snippet,
              text: "To Excel",
              function: () => {takeImageFailed()}),
          myButton.expandedIconButton(
              icon: Icons.card_membership,
              text: "Pdf tools",
              function: () => {takeImageFailed()}),
        ],
      );

  _mainBody() =>
      (dataList != null && dataList.length > 0) ? _listScanned() : _emptyList();

  _emptyList() => Expanded(child: Container(child: Text("You have no data")));

  _listScanned() {
    _background(File file) => Image.file(file);
    _bottomLayout(File file) => Positioned.fill(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                alignment: Alignment.centerLeft,
                color: Colors.white10,
                width: double.infinity,
                height: 30,
                padding: EdgeInsets.all(5),
                child: Text(
                  file.path,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: TextStyle(fontSize: 10),
                ),
              )),
        );

    return Expanded(
      child: GridView.count(
        crossAxisCount: 3,
        children: List.generate(dataList.length, (index) {
          var file = File(dataList[index].filePath);
          return Container(
            child: Card(
              child: InkWell(
                onTap: () {
                  handleTabItem(index);
                },
                child: Stack(
                  children: [_background(file), _bottomLayout(file)],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  void handleTabItem(int index) async {
    var file = File(dataList[index].filePath);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(file.path, dataList[index]),
      ),
    );
  }
}
