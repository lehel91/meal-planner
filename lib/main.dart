import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';

void main() {
  final db = AppDatabase();
  runApp(App(db: db));
}
