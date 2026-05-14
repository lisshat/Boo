import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BooLogo extends StatelessWidget {
  final double height;
  final Color? color;

  const BooLogo({super.key, this.height = 40, this.color});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/boo_logo.svg',
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}
