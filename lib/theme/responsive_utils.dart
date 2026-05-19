import 'package:flutter/material.dart';

extension ResponsiveExt on BuildContext {
  double get sw => MediaQuery.sizeOf(this).width;
  double get sh => MediaQuery.sizeOf(this).height;
  bool get isTablet => sw >= 600;
  double get hPad => (sw * 0.042).clamp(12.0, 24.0);
  double get chartH => (sh * 0.25).clamp(160.0, 250.0);
  double get statusBarH => MediaQuery.of(this).padding.top;
}
