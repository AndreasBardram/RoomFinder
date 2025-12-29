import 'package:flutter/material.dart';

Route<T> noTransition<T>(Widget page) => PageRouteBuilder<T>(
  pageBuilder: (_, __, ___) => page,
  transitionDuration: Duration.zero,
  reverseTransitionDuration: Duration.zero,
  transitionsBuilder: (_, __, ___, child) => child,
);

Future<T?> pushNoAnim<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push(noTransition<T>(page));

Future<T?> pushReplacementNoAnim<T extends Object?, TO extends Object?>(
  BuildContext context,
  Widget page, {
  TO? result,
}) =>
    Navigator.of(context).pushReplacement(noTransition<T>(page), result: result);

Future<T?> pushAndRemoveAllNoAnim<T>(BuildContext context, Widget page) =>
    Navigator.of(context).pushAndRemoveUntil(noTransition<T>(page), (_) => false);
