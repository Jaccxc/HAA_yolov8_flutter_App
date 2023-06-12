import 'package:crypto_tracker/core/res/color.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home/dashboard.dart';
import '../widgets/floating_action_ble_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<int> _counter1;
  late Future<int> _counter2;
  int threshDuration = -1;
  int threshAccum = -1;
  final TextEditingController threshDurationController = TextEditingController();
  final TextEditingController threshAccumController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();

    () async {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        threshDuration = await _getThreshDuration();
        threshAccum = await _getThreshAccum();
      });
    } ();
  }
  int _selectedBottomIndex = 0;
  static const page = DashboardScreen();

  Future<int> _getThreshDuration() async {
    _counter1 = _prefs.then((SharedPreferences prefs) {
      print('got record for duration');
      return prefs.getInt('durationThresh') ?? 900;
    });
    return _counter1;
  }
  Future<int> _getThreshAccum() async {
    _counter2 = _prefs.then((SharedPreferences prefs) {
      print('got record for accum');
      return prefs.getInt('accumThresh') ?? 3600;
    });
    return _counter2;
  }

  _saveThreshDuration(value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('durationThresh', value);
  }

  _saveThreshAccum(value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accumThresh', value);
  }

  dialogHealper(){
    late AwesomeDialog dialog;
    dialog = AwesomeDialog(
      context: context,
      animType: AnimType.scale,
      dialogType: DialogType.noHeader,
      keyboardAware: true,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Text(
              '設定',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(
              height: 10,
            ),
            Material(
              elevation: 0,
              color: Colors.blueGrey.withAlpha(40),
              child: TextFormField(
                controller: threshDurationController,
                autofocus: false,
                minLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: '裝置MAC位址',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Material(
              elevation: 0,
              color: Colors.blueGrey.withAlpha(40),
              child: TextFormField(
                key: _formKey,
                controller: threshAccumController,
                autofocus: false,
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: '資料特性位址',
                  prefixIcon: Icon(Icons.text_fields),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            AnimatedButton(
              isFixedHeight: false,
              text: '儲存',
              pressEvent: () {
                print('saving');
                if(threshDurationController.text.isNotEmpty){
                  threshDuration = int.parse(threshDurationController.value.text);
                  _saveThreshDuration(threshDuration);
                  threshDurationController.clear();
                }
                if(threshAccumController.text.isNotEmpty){
                  threshAccum = int.parse(threshAccumController.value.text);
                  _saveThreshAccum(threshAccum);
                  threshAccumController.clear();
                }
                dialog.dismiss();
              },
            )
          ],
        ),
      ),
    )..show();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _selectedBottomIndex == -1
          ? null
          : AppBar(
              foregroundColor: Color(0x440000),
              backgroundColor: Color(0x44000000),
              leading: Padding(
                padding: const EdgeInsets.only(left: 10.0, top: 10, bottom: 10),
                child: InkWell(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.format_shapes_sharp,
                      color: AppColors.bgColor,
                      size: 18,
                    ),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding:
                      const EdgeInsets.only(right: 15.0, top: 10, bottom: 10),
                  child: Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      InkWell(
                        onTap: () => dialogHealper(),
                        child: Icon(Icons.settings),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          width: 7,
                          height: 7,

                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
      body: page,
      floatingActionButton: BluetoothFloatingButton(),
    );
  }
}

class PositionedCircle extends StatelessWidget {
  final double? top, bottom, left, right;
  final double size;
  const PositionedCircle({
    Key? key,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      bottom: bottom,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 10,
              blurRadius: 40,
            )
          ],
          color: const Color(0xFf6d9bdd).withOpacity(0.05),
          //     shape: BoxShape.circle,
        ),
      ),
    );
  }
}

