import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context, String text) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            Padding(
              padding: EdgeInsets.only(left: 15),
              child: Text(text),
            ),
          ],
        ),
      );
    },
  );
}