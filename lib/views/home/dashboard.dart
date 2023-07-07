import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:sizer/sizer.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../models/save_and_load_handler.dart';
import '../../tflite/recognition.dart';
import '../../tflite/stats.dart';
import '../../widgets/box_widget.dart';
import '../../widgets/camera_view.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {

  String dateToday = "";

  List<Recognition>? results;
  Stats? stats;

  Uint8List? image;

  @override
  initState() {
    super.initState();
    DateTime now = DateTime.now();
    var formatter = DateFormat('yyyy/MM/dd');
    dateToday = formatter.format(now);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // _updateNIRView();
      },
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(image: DecorationImage(image: Image.asset("assets/design.png").image, fit: BoxFit.cover)),
          child: Stack(
            children: <Widget>[
            // Camera View
              Padding(
                  padding: const EdgeInsets.only(left:0.0, right: 0.0, top: 100.0),
                  child: CameraView(resultsCallback, statsCallback),
              ),
              Padding(
                padding: const EdgeInsets.only(left:0.0, right: 0.0, top: 100.0),
                child: Container(
                  child: boundingBoxes(results),
                ),
              ),
              ]
            ),
          ),

    );
  }
  Widget boundingBoxes(List<Recognition>? results) {
    if (results == null) {
      return Container();
    }
    return Stack(
      children: results
          .map((e) => BoxWidget(
        result: e, key: UniqueKey(),
      ))
          .toList(),
    );
  }
  
  /// Callback to get inference results from [CameraView]
  void resultsCallback(List<Recognition> results) {
    setState(() {
      this.results = results;
    });
  }

  /// Callback to get inference stats from [CameraView]
  void statsCallback(Stats stats) {
    setState(() {
      this.stats = stats;
    });
  }
}


class FrostedGlassBox extends StatelessWidget {
  final double width, height;
  final Widget child;

  const FrostedGlassBox({required Key key, required this.width, required this.height, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: Container(
        width: width,
        height: height,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 7.0,
                sigmaY: 7.0,
              ),
              child: Container(width: width, height: height, child: const Text(" ")),
            ),
            Opacity(
                opacity: 0.15,
                child: Image.asset(
                  "assets/noise.png",
                  fit: BoxFit.cover,
                  width: width,
                  height: height,
                )),
            Container(
              decoration: BoxDecoration(
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 30, offset: Offset(2, 2))],
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ], stops: const [
                    0.0,
                    1.0,
                  ])),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class noDataOnThisDate extends StatelessWidget{
  final String date;
  noDataOnThisDate({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
        child: Column(
          children: [
            const SizedBox(
              height: 30,
            ),
            Align(
              child: Text(
                date,
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Align(
              child: Text(
                "目前沒有資料",
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 26, fontWeight: FontWeight.bold),
              ),
            )
          ],
        )
    );
  }
}

class DynamicItem extends StatelessWidget {
  final Map<String, dynamic>? data;
  final Function(List<double>) onTapData;

  DynamicItem({required this.data, required this.onTapData});

  final Color textColor = Colors.white.withOpacity(0.7);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: (){ onTapData((data?["PPGSequence"][0] as List<dynamic>).cast<double>()); },
        onLongPress: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              // return object of type Dialog
              return AlertDialog(
                title: const Text("Delete Data"),
                content: const Text("Are you sure you want to delete this item?"),
                actions: <Widget>[
                  // usually buttons at the bottom of the dialog
                  TextButton(
                    child: const Text("Yes"),
                    onPressed: () {
                      // put your delete function here
                      deleteDataByDate(data?["datetime"]);
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text("No"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
        child: Container(
          child: Center(
            child: FrostedGlassBox(
              key: UniqueKey(),
              width: 100.w,
              height: 160,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 1.2,
                      child: Text(
                        " \n     ${data?["datetime"].substring(0,10)}",
                        style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          heightFactor: 0.55,
                          alignment: Alignment.topLeft,
                          child: Text(
                            "       NIR測量時間:             \n",
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ),
                        Align(
                          heightFactor: 0.55,
                          alignment: Alignment.topRight,
                          child: Text(
                            "   測量種類: ${data?["type"]}\n",
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        )
                      ],
                    ),

                    Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 0.7,
                      widthFactor: 5.5,
                      child: Text(
                        "               ${data?["datetime"].substring(11,19)}\n",
                        style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          heightFactor: 0.55,
                          alignment: Alignment.topLeft,
                          child: Text(
                            "       NIR測量時長:               \n",
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        ),
                        Align(
                          heightFactor: 0.55,
                          alignment: Alignment.topRight,
                          child: Text(
                            "      預測值: ${((data?["prediction"])%150).toStringAsFixed(2)}\n",
                            style: TextStyle(color: textColor, fontSize: 16),
                          ),
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      heightFactor: 0,
                      child: Text(
                        "               00:00:0${2}\n",
                        style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.normal
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
    );
  }
}

