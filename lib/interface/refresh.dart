import 'package:flutter/material.dart';

abstract class RefreshableState<T extends StatefulWidget> extends State<T> {
  Future<void> refresh();
}
