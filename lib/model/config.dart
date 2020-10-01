import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import 'data_models.dart';

class Config {
  static const String BOX_NAME = "box_name";
  static const String DATA_NAME = "data_name";
}

class Converter {
  List<DataFile> parseDataFile(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<DataFile>((json) => DataFile.fromJson(json)).toList();
  }
}
class AppUtil{
  static Future<String> getFileNameWithExtension(File file)async{
    if(await file.exists()){
      //To get file name without extension
      //path.basenameWithoutExtension(file.path);
      //return file with file extension
      return path.basename(file.path);
    }else{
      return null;
    }
  }

}