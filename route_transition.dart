import 'package:flutter/material.dart';

class RouteSlideTransition extends PageRouteBuilder {
  final Widget widget;
  final Offset from; // Offset(0.0, -1.0) -slide down, Offset(0.0, 1.0) -slide up

  SlideDownRoute({this.widget, this.from})
      : super(pageBuilder: (BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return widget;
  }, transitionsBuilder: (BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return new SlideTransition(
      position: new Tween<Offset>(
        begin: from, 
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  });
}

