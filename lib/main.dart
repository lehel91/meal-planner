import 'package:flutter/material.dart';

import 'app.dart';
import 'data/database.dart';
import 'data/drift_repository.dart';

void main() {
  final repository = DriftRepository(AppDatabase());
  runApp(App(repository: repository));
}
