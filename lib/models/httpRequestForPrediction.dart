import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<double> requestPrediction(List<List<double>> PPGSequence) async {
  String type = "";
  final String _IP_ADDRESS = "120.126.151.169:5000";
  Map<String, dynamic>? pollResponseBody = null;

  if(PPGSequence.length == 3){
    type = "nir_bg";
  } else {
    type = "nir_ua";
  }

  List<double> list810 = [];
  List<double> list860 = [];
  List<double> list940 = [];

  late Map<String, dynamic> json_map_object;

  if(type == "nir_ua"){
    list810 = PPGSequence[0];
    list860 = PPGSequence[1];

    json_map_object = {
      "type": "nir_ua",
      "data": {
        "810": list810,
        "860": list860,
      },
    };

  } else if (type == "nir_bg") {
    list810 = PPGSequence[0];
    list860 = PPGSequence[1];
    list940 = PPGSequence[2];

    json_map_object = {
      "type": "nir_bg",
      "data": {
        "810": list810,
        "860": list860,
        "940": list940,
      },
    };
  }

  String json = jsonEncode(json_map_object);

  print(json); // Prints: {"type":"abc","data":{"810":[0.0,1.0,2.0,3.0],"860":[0.0,1.0,2.0,3.0]}}

  // define the headers
  Map<String, String> headers = {"Content-type": "application/json"};

  // send the HTTP POST request
  http.Response response = await http.post(
    Uri.parse('http://$_IP_ADDRESS/store_data'),
    headers: headers,
    body: json,
  );

  // print the HTTP response
  if (response.statusCode == 200) {
    print('Response body: ${response.body}');
  } else {
    print('Request failed with status: ${response.statusCode}.');
  }
  // parse the initial response
  if (response.statusCode == 200) {
    Map<String, dynamic> responseBody = jsonDecode(response.body);
    var id = responseBody['id'];
    var accessKey = responseBody['access_key'];
    // start polling
    Timer.periodic(Duration(milliseconds: 500), (Timer timer) async {
      // the polling request
      print("reqeusting with id=$id key=$accessKey");
      var pollResponse = await http.get(
        Uri.parse('http://120.126.151.169:5000/get_data?id=$id&type=$type&access_key=$accessKey'),
      );

      pollResponseBody = jsonDecode(pollResponse.body);
      // parse the polling response
      if (pollResponseBody!['code'] == 200) {
        // stop the timer when the response content is not empty
        timer.cancel();
        // handle the polling response
        print('Success, Polling response body: ${pollResponse.body}');
      } else {
        print('Failed, Polling response body: ${pollResponse.body}');
      }
    });
  } else {
    print('Initial request failed with status: ${response.statusCode}.');
  }

  if(pollResponseBody == null){
    return -0.1;
  } else {
    return pollResponseBody!['result'];
  }
}