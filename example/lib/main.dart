import 'package:community_toolkit/locator.dart';
import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Bootstrap the built-in ServiceLocator with app-wide singletons.
  ServiceLocator.I.register<Messenger>(Messenger());

  runApp(const ToolkitExampleApp());
}
