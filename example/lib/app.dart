import 'package:flutter/material.dart';

import 'counter/counter_view.dart';
import 'login/login_view.dart';
import 'shop/shop_view.dart';

class ToolkitExampleApp extends StatelessWidget {
  const ToolkitExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Community Toolkit Example',
    theme: ThemeData(
      colorSchemeSeed: Colors.deepOrange,
      useMaterial3: true,
      brightness: Brightness.dark,
    ),
    home: const _ExampleTabs(),
  );
}

class _ExampleTabs extends StatelessWidget {
  const _ExampleTabs();

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Community Toolkit'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calculate), text: 'Counter'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Shop'),
            Tab(icon: Icon(Icons.login), text: 'Login'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [CounterView(), ShopView(), LoginView()],
      ),
    ),
  );
}
