import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// can be used with MemoryImage where you need ImageProvider
final onePixelImg = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

DateFormat _df = DateFormat.yMMMd();

formatDate(DateTime date) {
  if (date == null) {
    return null;
  }
  return _df.format(date);
}

parseFormatted(String formatted) {
  return _df.parse(formatted);
}

formatDateDiff(DateTime date) {
  if (date == null) return '';
  var diff = DateTime.now().difference(date).inDays;
  if (diff > 365) return '${(diff / 365).toStringAsFixed(0)} year(s)';
  if (diff > 30) return '${(diff / 30).toStringAsFixed(0)} month(s)';
  return '$diff day(s)';
}

formatBigNumber(int num) {
  if (num == null) return '0';
  var m = 1000000;
  var k = 1000;
  var s = '';
  var d = 1;
  if (num >= m) {
    d = m;
    s = 'M';
  } else if (num >= k) {
    d = k;
    s = 'K';
  } else {
    return num.toString();
  }
  return '${(num / d).toStringAsFixed((num % d >= d / 10) ? 1 : 0)}$s';
}

bool isValidEmail(value) {
  return RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value);
}

// open snack bar
void snack(source, String text,
    {Duration duration = const Duration(milliseconds: 1000)}) {
  var scaff;
  if (source is BuildContext) scaff = Scaffold.of(source);
  if (source is ScaffoldState) scaff = source;
  if (source is GlobalKey<ScaffoldState>) scaff = source.currentState;
  scaff
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: duration,
      ),
    );
}

const noop = Function;

showConfirmationDialog(BuildContext ctx,
    {String title,
    String content,
    Function onConfirm,
    Function onCancel,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm'}) {
  if (Platform.isIOS) {
    return showCupertinoDialog(
        context: ctx,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Container(
                margin: EdgeInsets.only(bottom: 8), child: Text(title)),
            content: Text(content),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text(
                  cancelText,
                ),
                onPressed: onCancel,
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text(confirmText),
                onPressed: onConfirm,
              ),
            ],
          );
        });
  } else {
    return showDialog(
        context: ctx,
        builder: (_) {
          return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: <Widget>[
              FlatButton(
                child: Text(cancelText),
                onPressed: onCancel,
              ),
              FlatButton(
                child: Text(confirmText, style: TextStyle(color: Colors.red,),),
                onPressed: onConfirm,
              ),
            ],
          );
        });
  }
}

