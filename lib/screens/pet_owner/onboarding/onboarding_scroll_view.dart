import 'package:flutter/material.dart';

class OnboardingScrollView extends StatelessWidget {
  final Widget child;
  final double horizontalPadding;

  const OnboardingScrollView(
      {super.key, required this.child, this.horizontalPadding = 24});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
