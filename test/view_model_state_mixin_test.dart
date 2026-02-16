import 'package:community_toolkit/mvvm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterViewModel extends BaseViewModel {
  late final count = notifier(0);
  bool initRan = false;

  @override
  Future<void> init() async {
    initRan = true;
  }
}

class _TestScreen extends StatefulWidget {
  const _TestScreen();

  @override
  State<_TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<_TestScreen>
    with ViewModelStateMixin<_TestScreen, _CounterViewModel> {
  bool onReadyCalled = false;

  @override
  _CounterViewModel createViewModel() => _CounterViewModel();

  @override
  void onViewModelReady(_CounterViewModel viewModel) {
    onReadyCalled = true;
  }

  @override
  Widget build(BuildContext context) => Bind<int>(
    notifier: vm.count,
    builder: (value) => Text('$value', textDirection: TextDirection.ltr),
  );
}

void main() {
  group('ViewModelStateMixin', () {
    testWidgets('creates ViewModel and renders', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestScreen()));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('calls onViewModelReady', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestScreen()));
      final state = tester.state<_TestScreenState>(find.byType(_TestScreen));
      expect(state.onReadyCalled, isTrue);
    });

    testWidgets('calls initialize after onViewModelReady', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestScreen()));
      // Let the unawaited initialize() microtask complete.
      await tester.pump();
      final state = tester.state<_TestScreenState>(find.byType(_TestScreen));
      expect(state.vm.initRan, isTrue);
      expect(state.vm.isInitialized, isTrue);
      expect(state.vm.loadingNotifier.value, isFalse);
    });

    testWidgets('vm getter provides access to ViewModel', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestScreen()));
      final state = tester.state<_TestScreenState>(find.byType(_TestScreen));
      state.vm.count.value = 5;
      await tester.pump();
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('disposes ViewModel when widget is removed', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _TestScreen()));
      final state = tester.state<_TestScreenState>(find.byType(_TestScreen));
      final count = state.vm.count;

      // Remove the widget.
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));

      // The notifier should be disposed.
      expect(() => count.addListener(() {}), throwsFlutterError);
    });
  });
}
