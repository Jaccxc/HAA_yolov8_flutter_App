import 'dart:ffi';
import 'dart:math';
import 'dart:convert';
import 'dart:ui';
import 'package:crypto_tracker/widgets/crypto_card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';

import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';

// To parse this JSON data, do
//
//     final goatLog = goatLogFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

Future<http.Response> fetchDataFromIDTypeAccessKey(String id, String type, String access_key) async {
  Map<String, String> qParams = {
    'id': id,
    'type': type,
    'access_key': access_key,
  };

  var url = Uri.http("120.126.151.169:5000", "/get_data", qParams);

  print(url);

  // Inside an async function, you can then pass this to http.get
  final response = await http.get(url);

  return response;
}

int threshDuration = -1;
int threshAccum = -1;

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final maxSpeed = 2;
  final maxTheta = 2 * pi;
  final maxRadius = 10;
  var dataLength = 0;
  String currentSelectedDate = '1990/1/1';
  List<DynamicItem> DynamicList = [];
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<int> _counter1;
  late Future<int> _counter2;


  void _updateGoatView(String date) async{
    // var response = await fetchDataFromDate(date);
    // print('Response status: ${response.statusCode}');
    print('Response body:');
    // var parsedGoatLog = goatLogFromJson(response.body);

    // print(parsedGoatLog);

    DynamicList.clear();

    int currentKey = 1;
    // while(parsedGoatLog.containsKey(currentKey.toString())){
    //   DynamicList.add(new DynamicItem(data: parsedGoatLog[currentKey.toString()],));
    //   currentKey++;
    // }

    threshDuration = await _getThreshDuration();
    threshAccum = await _getThreshAccum();

    print('Length: ${DynamicList.length}');
    setState(() { });
  }

  @override
  initState() {
    super.initState();
    () async {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        DateTime now = new DateTime.now();
        var formatter = new DateFormat('yyyy/MM/dd');
        String formattedDate = formatter.format(now);
        _updateGoatView(formattedDate);
        currentSelectedDate = formattedDate;
        threshDuration = await _getThreshDuration();
        threshAccum = await _getThreshAccum();
        print(threshDuration);
        print(threshAccum);
        setState(() {});
      });
    } ();
  }

  Future<int> _getThreshDuration() async {
    _counter1 = _prefs.then((SharedPreferences prefs) {
      return prefs.getInt('durationThresh') ?? 900;
    });
    return _counter1;
  }
  Future<int> _getThreshAccum() async {
    _counter2 = _prefs.then((SharedPreferences prefs) {
      return prefs.getInt('accumThresh') ?? 3600;
    });
    return _counter2;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return RefreshIndicator(
      onRefresh: () async {
        _updateGoatView(currentSelectedDate);
      },
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(image: DecorationImage(image: Image.asset("assets/design.png").image, fit: BoxFit.cover)),
        child: ListView.builder(
          itemCount: DynamicList.length+1,
          itemBuilder: (_, index) {
            return new Padding(
              padding: new EdgeInsets.all(10.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    margin: new EdgeInsets.only(left: 10.0),
                  ),
                  (index == 0) ?  Container(
                    height: 250,
                    child: Card(
                    )
                  ) : DynamicList[index-1],
                  (DynamicList.length == 0) ? noDataOnThisDate( date: currentSelectedDate) : Container(),
                ],
              ) ,
            );
          },
        ),
      ),
    );
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
              child: Container(width: width, height: height, child: Text(" ")),
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
                  ], stops: [
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
              "${date}",
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
  // final GoatLog? data;
  // DynamicItem({required this.data});
  final Color textColor = Colors.white.withOpacity(0.7);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // showImageViewer(
            // context,
            // Image.network("http://jacc.tw:5000/getImage?IMG_ID=" + (data?.imgId ?? 0).toString())
            //     .image,
            // swipeDismissible: true);
      },
      child: Container(
        // child: Center(
        //   child: FrostedGlassBox(
        //     key: UniqueKey(),
        //     width: 100.w,
        //     height: 180,
        //     child: Center(
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.start,
        //         children: [
        //           Align(
        //             alignment: Alignment.topLeft,
        //             heightFactor: 1.2,
        //             child: Text(
        //               " \n     ${data?.logTime.year}-${data?.logTime.month}-${data?.logTime.day},  ${data?.logTime.hour}:${data?.logTime.minute}:${data?.logTime.second}",
        //               style: TextStyle(color: textColor, fontSize: 17, fontWeight: FontWeight.bold),
        //             ),
        //           ),
        //
        //           Row(
        //             mainAxisAlignment: MainAxisAlignment.start,
        //             children: [
        //               Align(
        //                 heightFactor: 0.55,
        //                 alignment: Alignment.topLeft,
        //                 child: Text(
        //                   "       單次連續出現時長:             \n",
        //                   style: TextStyle(color: textColor, fontSize: 16),
        //                 ),
        //               ),
        //               Align(
        //                 heightFactor: 0.55,
        //                 alignment: Alignment.topRight,
        //                 child: Text(
        //                   "羊隻編號: ${data?.id}\n",
        //                   style: TextStyle(color: textColor, fontSize: 16),
        //                 ),
        //               )
        //             ],
        //           ),
        //
        //           Align(
        //             alignment: Alignment.topLeft,
        //             heightFactor: 0.7,
        //             widthFactor: 5.5,
        //             child: Text(
        //               "           ${data?.duration.hour}:${data?.duration.minute}:${data?.duration.second}\n",
        //               style: TextStyle(
        //                   color: (int.parse(data?.duration.totalSeconds ?? "") < threshDuration) ?
        //                   textColor : Colors.red.shade800.withOpacity(0.7),
        //                   fontSize: 16,
        //                   fontWeight: (int.parse(data?.duration.totalSeconds ?? "") < threshDuration) ?
        //                   FontWeight.normal : FontWeight.bold
        //               ),
        //             ),
        //           ),
        //
        //           Row(
        //             mainAxisAlignment: MainAxisAlignment.start,
        //             children: [
        //               Align(
        //                 heightFactor: 0.55,
        //                 alignment: Alignment.topLeft,
        //                 child: Text(
        //                   "       總出現時長:                          \n",
        //                   style: TextStyle(color: textColor, fontSize: 16),
        //                 ),
        //               ),
        //               Align(
        //                 heightFactor: 0.55,
        //                 alignment: Alignment.topRight,
        //                 child: Text(
        //                   "影像編號: ${data?.imgId}\n",
        //                   style: TextStyle(color: textColor, fontSize: 16),
        //                 ),
        //               )
        //             ],
        //           ),
        //           Align(
        //             alignment: Alignment.topLeft,
        //             heightFactor: 0,
        //             child: Text(
        //               "           ${data?.accumulation.hour}:${data?.accumulation.minute}:${data?.accumulation.second}\n",
        //               style: TextStyle(
        //                   color: (int.parse(data?.accumulation.totalSeconds ?? "") < threshAccum) ?
        //                   textColor : Colors.red.shade900.withOpacity(0.7),
        //                   fontSize: 16,
        //                   fontWeight: (int.parse(data?.accumulation.totalSeconds ?? "") < threshAccum) ?
        //                   FontWeight.normal : FontWeight.bold),
        //             ),
        //           ),
        //
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      )
    );
  }
}

