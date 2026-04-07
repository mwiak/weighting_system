import 'package:fluent_ui/fluent_ui.dart';

class LoadingButton extends StatefulWidget {
  final String label;
  final Function onPressed;
  const LoadingButton(
      {super.key, required this.onPressed, required this.label});

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool isLoading = false;
  bool isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      SizedBox.shrink();
    } else if (isLoading) {
      return ProgressRing();
    }

    return FilledButton(
        child: Text(widget.label),
        onPressed: () {
          widget.onPressed.call();
        });
  }

  void setLoading() async {
    setState(() {
      isLoading = true;
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      isVisible = false;
    });
  }
}
