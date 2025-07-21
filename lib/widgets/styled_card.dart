import 'package:flutter/cupertino.dart';
import '../main.dart'; // For theme colors like kCardBackgroundLight

class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final Gradient? gradient;
  final VoidCallback? onTap; // Added onTap callback

  const StyledCard({
    Key? key,
    required this.child,
    this.margin = const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
    this.padding = const EdgeInsets.all(16.0),
    this.color,
    this.borderRadius,
    this.boxShadow,
    this.border,
    this.gradient,
    this.onTap, // Added onTap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // final bool isDarkMode = CupertinoTheme.of(context).brightness == Brightness.dark;

    Widget cardContent = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: onTap != null ? null : (color ?? kCardBackgroundLight), // If tappable, color might be handled by CupertinoButton
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(14.0),
        border: border,
        boxShadow: boxShadow ?? (onTap != null ? null : [ // No shadow if it's a button-like card to avoid double visual cues
          BoxShadow(
            color: CupertinoColors.systemGrey4.withOpacity(0.20), // Softer shadow
            blurRadius: 16.0, // Slightly more blur
            spreadRadius: -2.0, // Negative spread for inset-like feel
            offset: const Offset(0, 6),
          ),
        ]),
      ),
      child: child,
    );

    if (onTap != null) {
      return Padding( // Apply margin outside the button
        padding: margin ?? EdgeInsets.zero,
        child: CupertinoButton(
          padding: EdgeInsets.zero, // Button itself has no padding, cardContent does
          onPressed: onTap,
          borderRadius: borderRadius ?? BorderRadius.circular(14.0),
          color: color ?? kCardBackgroundLight, // Background color for the button
          child: cardContent,
        ),
      );
    }

    return Container(
      margin: margin,
      child: cardContent, // If not tappable, use the original structure
    );
  }
}