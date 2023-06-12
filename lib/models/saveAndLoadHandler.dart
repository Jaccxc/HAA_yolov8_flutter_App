import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File> get _localFile async {
  final directory = await getApplicationDocumentsDirectory();
  // print(directory.path);
  return File('${directory.path}/nir_data.json');
}

void saveToLocal(List<List<double>> PPGSequence, String type, double prediction) async {
  final file = await _localFile;



  print("writing to local...");
  // Read the file
  Map<String, dynamic> data = {};
  if (await file.exists()) {
    final contents = await file.readAsString();
    data = json.decode(contents);
  }

  String date_data = DateTime.now().toIso8601String();

  // Append new data
  final newData = {
    "datetime": date_data,
    "type": type,
    "prediction": prediction,
    "PPGSequence": PPGSequence,
  };
  data[date_data] = newData;

  // Write the file
  file.writeAsString(json.encode(data));
  print("save file done.");
}

void deleteDataByDate(String date) async {
  final file = await _localFile;

  print("Deleting from local...");
  // Read the file
  Map<String, dynamic> data = {};
  if (await file.exists()) {
    final contents = await file.readAsString();
    data = json.decode(contents);
  }

  // Remove the data with the specified date key
  if (data.containsKey(date)) {
    data.remove(date);
  } else {
    print("Data with date $date not found.");
  }

  // Write the file
  file.writeAsString(json.encode(data));
  print("Delete file done.");
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