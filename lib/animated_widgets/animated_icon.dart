import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/widgets.dart';

class SimpleAnimatedIcon extends StatefulWidget {
  const SimpleAnimatedIcon({Key? key}) : super(key: key);

  @override
  State<SimpleAnimatedIcon> createState() => _SimpleAnimatedIconState();
}

class _SimpleAnimatedIconState extends State<SimpleAnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation; // To drive the scale

  @override
  void initState() {
    super.initState();

    // 1. Initialize the AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 1 second for a slow pulse
    );

    // 2. Create a Tween to define the scale range
    // We want it to go from 1.0 (normal size) to 1.2 (120% size)
    final Tween<double> scaleTween = Tween<double>(begin: 1.0, end: 1.10);

    // 3. Create the animation, using a Curve for a smooth effect
    _scaleAnimation = scaleTween.animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear, // This makes the pulse look natural
      ),
    );

    // 4. Start the animation and make it repeat
    _controller.repeat(reverse: true); // 'reverse: true' makes it pulse
  }

  @override
  void dispose() {
    // 5. Always dispose of the controller
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. Use ScaleTransition instead of AnimatedIcon
    return SizedBox(
      height: 30,
      width: 40,
      child: ScaleTransition(
        scale: _scaleAnimation, // Pass in our custom scale animation
        child: Icon(
          FluentIcons.alert_solid, // Use a standard Fluent icon
          size: 30, // Define a base size
          color: Colors.orange.withOpacity(0.5),
        ),
      ),
    );
  }
}
