import 'package:flutter/cupertino.dart';
import '../main.dart'; // For kAppPrimaryColor

class AppLogo extends StatelessWidget {
  final double size;
  const AppLogo({Key? key, this.size = 60.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_logo.png', // Path to your logo
      width: size,
      height: size,
      fit: BoxFit.contain, // Adjust fit as needed
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image doesn't load or path is incorrect
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: kAppPrimaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(size * 0.20), // Rounded square
          ),
          child: Icon(
            CupertinoIcons.rocket_fill, // A more dynamic fallback icon
            size: size * 0.6,
            color: kAppPrimaryColor,
          ),
        );
      },
    );
  }
}