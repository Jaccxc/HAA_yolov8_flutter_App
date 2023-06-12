import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/http_request_for_prediction.dart';
import '../models/save_and_load_handler.dart';
import 'loading_dialog.dart';

class BluetoothFloatingButton extends StatefulWidget {
  @override
  _BluetoothFloatingButtonState createState() =>
      _BluetoothFloatingButtonState();
}

class _BluetoothFloatingButtonState extends State<BluetoothFloatingButton> {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool _isConnected = false;
  bool _isListening = false;

  final String _NIRS_TYPE = "nir_bg"; // OR "nir_ua"
  final String _DEVICE_MAC_ADDRESS = "84:CC:A8:78:48:42";
  final Guid _DATA_CHAR_UUID = Guid("43ada7f1-7ec0-4e14-a4af-920859b5b7e5");
  final Guid _REQUEST_CHAR_UUID = Guid("43ada7f1-7ec0-4e14-ccaf-920859b5a9e5");
  final Guid _END_NOTIFY_CHAR_UUID = Guid("43ada7f1-7ec0-4e14-aabf-920859b5a9e5");

  List<double> floatBuffer = [];
  List<List<double>> currentPPGSequence = [];

  BluetoothCharacteristic? _dataCharacteristic;
  BluetoothCharacteristic? _requestCharacteristic;
  BluetoothCharacteristic? _endNotifyCharacteristic;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _onPressed,
      child: Icon(_isConnected ? Icons.send : Icons.bluetooth),
    );
  }

  Future<void> _onPressed() async {
    if (!_isConnected) {
      _connectBLE();
    } else {
      _sendStartOp();
    }
    setState(() {});
  }

  void _splitListIntoSegments(List<double> allFloats) {
    int segments = _NIRS_TYPE == "nir_bg" ? 3 : 2;

    if (allFloats.length % segments != 0) {
      return;
      // throw Exception("The length of the list is not divisible by the number of segments");
    }

    int segmentSize = allFloats.length ~/ segments;

    currentPPGSequence = [];

    for (int i = 0; i < segments; i++) {
      var start = i * segmentSize;
      var end = start + segmentSize;
      currentPPGSequence.add(allFloats.sublist(start, end));
    }
  }

  void _connectBLE() async {
    showLoadingDialog(context, "Connecting...");
    List<ScanResult> scanResults = await flutterBlue.startScan(
        timeout: const Duration(seconds: 4), allowDuplicates: false);

    // address = "32:6e:db:a5:25:b8"
    // uuid = "4f609f09-3104-40b2-9652-5c36b39c46c1"

    for (ScanResult scanResult in scanResults) {
      // 检查设备ID
      if (scanResult.device.id.id == _DEVICE_MAC_ADDRESS) {
        print("Device Found: $_DEVICE_MAC_ADDRESS");
        // 停止扫描
        if (flutterBlue.isScanningNow) {
          flutterBlue.stopScan();
        }
        // device = result.device;
        // 连接设备
        scanResult.device.connect();
        while((await flutterBlue.connectedDevices).isEmpty);
        break;
      }
    };

    // 停止扫描
    if (flutterBlue.isScanningNow) {
      flutterBlue.stopScan();
    }

    List<BluetoothDevice> devices = await flutterBlue.connectedDevices;
    if (devices.isEmpty){
      print('No device found');
      _isConnected = false;
      setState(() {});
      return;
    } else {
      _isConnected = true;
      setState(() {});
    }

    BluetoothDevice? device = devices[0];
    List<BluetoothService>? services = await device.discoverServices();
    services.forEach((service) async {
      var characteristics = service.characteristics;
      for (BluetoothCharacteristic c in characteristics) {
        if (c.uuid == _DATA_CHAR_UUID) {
          _dataCharacteristic = c;
        } else if (c.uuid == _REQUEST_CHAR_UUID) {
          _requestCharacteristic = c;
        } else if (c.uuid == _END_NOTIFY_CHAR_UUID) {
          _endNotifyCharacteristic = c;
        }
      }
    });

    if (_dataCharacteristic == null) {
      print("dataCharacteristic not found");
    } else {
      print(_dataCharacteristic);
    }
    if (_requestCharacteristic == null) {
      print("requestCharacteristic not found");
    } else {
      print(_requestCharacteristic);
    }
    if (_endNotifyCharacteristic == null) {
      print("endNotifyCharacteristic not found");
    } else {
      print(_endNotifyCharacteristic);
    }

    await device.requestMtu(250);

    print("finish");
    Navigator.pop(context);
  }

  void _sendStartOp() async {
    showLoadingDialog(context, "Recording...");

    List<BluetoothDevice> devices = await flutterBlue.connectedDevices;
    if (devices.isEmpty){
      print('Disconnected');
      _isConnected = false;
      setState(() {});
      return;
    }

    if(!_isListening){
      await _dataCharacteristic?.setNotifyValue(true);
      await _endNotifyCharacteristic?.setNotifyValue(true);

      _dataCharacteristic?.onValueChangedStream.listen((value) async{
        // print("notify value: $value, len=${value.length}");
        final bytes = Uint8List.fromList(value);

        for (var i = 0; i < bytes.length; i += 4) {
          final byteData = bytes.buffer.asByteData(i, 4);
          double value = byteData.getFloat32(0, Endian.little);
          print(value); // Prints the float value
          if(value > -100){
            floatBuffer.add(value);
          }
        }

      });
      _endNotifyCharacteristic?.onValueChangedStream.listen((value) async{
        final bytes = Uint8List.fromList(value);
        final byteData = bytes.buffer.asByteData(0, 4);
        double float_value = byteData.getFloat32(0, Endian.little);
        print("end notify value: $float_value");

        _splitListIntoSegments(floatBuffer);

        for (int i = 0; i < currentPPGSequence.length; i++) {
          for (int j = 0; j < currentPPGSequence[i].length; j++) {
            print('Element at [$i][$j]: ${currentPPGSequence[i][j]}');
          }
        }
        Navigator.pop(context);

        showLoadingDialog(context, "Predicting...");
        double prediction = await requestPrediction(currentPPGSequence);
        saveToLocal(currentPPGSequence, _NIRS_TYPE, prediction);
        Navigator.pop(context);
      });
      _isListening = true;
    }

    floatBuffer = [];
    await _requestCharacteristic?.write([3], withoutResponse: true);
    print("finish");

  }
}
