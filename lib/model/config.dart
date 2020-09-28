import 'dart:convert';

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
