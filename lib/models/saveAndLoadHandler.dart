import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> get _localFile async {
  final directory = await getApplicationDocumentsDirectory();
  return File('${directory.path}/nir_data.json');
}

void saveToLocal(List<List<double>> PPGSequence, String type, double prediction) async {
  final file = await _localFile;

  // Read the file
  Map<String, dynamic> data = {};
  if (await file.exists()) {
    final contents = await file.readAsString();
    data = json.decode(contents);
  }

  // Append new data
  final newData = {
    "datetime": DateTime.now().toIso8601String(),
    "type": type,
    "prediction": prediction,
    "PPGSequence": PPGSequence,
  };
  data[DateTime.now().toIso8601String()] = newData;

  // Write the file
  file.writeAsString(json.encode(data));
}

Future<List<Map<String, dynamic>>> loadFromLocal() async {
  try {
    final file = await _localFile;

    // Read the file
    final contents = await file.readAsString();
    final data = json.decode(contents);

    return List<Map<String, dynamic>>.from(data.values);
  } catch (e) {
    // If encountering an error, return empty list
    return [];
  }
}