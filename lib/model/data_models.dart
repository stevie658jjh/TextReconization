import 'dart:convert';

class DataFile {
  String filePath;

  String textDetected;

  DataFile(this.filePath, this.textDetected);

  factory DataFile.fromJson(Map<String, dynamic> json) {
    return DataFile(json['filePath'] as String, json['textDetected'] as String);
  }

  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'textDetected': textDetected,
    };
  }
}
