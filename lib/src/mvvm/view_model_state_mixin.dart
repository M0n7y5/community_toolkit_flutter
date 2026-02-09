import 'package:flutter/widgets.dart';

import 'base_view_model.dart';

/// A mixin for [State] that manages the lifecycle of a [BaseViewModel].
///
/// This eliminates the boilerplate of creating the ViewModel in [initState]
/// and disposing it in [dispose] — the two most repeated lines in every
/// screen that uses MVVM.
///
/// ### Before
///
/// ```dart
/// class _DetailScreenState extends State<DetailScreen> {
///   late final DetailViewModel _vm;
///
///   @override
///   void initState() {
///     super.initState();
///     _vm = DetailViewModel(contentId: widget.contentId);
///   }
///
///   @override
///   void dispose() {
///     _vm.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) { ... }
/// }
/// ```
///
/// ### After
///
/// ```dart
/// class _DetailScreenState extends State<DetailScreen>
///     with ViewModelStateMixin<DetailScreen, DetailViewModel> {
///   @override
///   DetailViewModel createViewModel() =>
///       DetailViewModel(contentId: widget.contentId);
///
///   @override
///   Widget build(BuildContext context) { ... }
/// }
/// ```
///
/// The ViewModel is accessible via the [vm] getter.
mixin ViewModelStateMixin<W extends StatefulWidget, VM extends BaseViewModel>
    on State<W> {
  late final VM _viewModel;

  /// The ViewModel instance managed by this mixin.
  ///
  /// This is safe to access after [initState] has been called (i.e., in
  /// [build], event handlers, etc.).
  VM get vm => _viewModel;

  /// Creates the ViewModel instance.
  ///
  /// This is called once during [initState]. Override this to construct
  /// the ViewModel with any required parameters from the widget.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// DetailViewModel createViewModel() =>
  ///     DetailViewModel(contentId: widget.contentId);
  /// ```
  VM createViewModel();

  /// Called after the ViewModel is created during [initState].
  ///
  /// Override this to perform any additional setup that requires the
  /// ViewModel to exist, such as adding listeners to the ViewModel's
  /// notifiers for showing SnackBars or navigating.
  ///
  /// The default implementation does nothing.
  void onViewModelReady(VM viewModel) {}

  @override
  void initState() {
    super.initState();
    _viewModel = createViewModel();
    onViewModelReady(_viewModel);
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }
}
