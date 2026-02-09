import 'package:flutter/material.dart';
import 'counter/counter_view.dart';
import 'shop/shop_view.dart';

class MvvmExampleApp extends StatelessWidget {
  const MvvmExampleApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: ExampleTabs());
}

class ExampleTabs extends StatelessWidget {
  const ExampleTabs({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('MVVM Framework Example'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.calculate), text: 'Counter'),
            Tab(icon: Icon(Icons.shopping_bag), text: 'Shop'),
          ],
        ),
      ),
      body: const TabBarView(children: [CounterView(), ShopView()]),
    ),
  );
}
