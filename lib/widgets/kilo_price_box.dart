import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:weighing_system/widgets/weighing_tab_content.dart';

class KiloPriceBox extends StatefulWidget {
  final TextEditingController controller;
  final Function onChange;

  const KiloPriceBox(
      {super.key, required this.controller, required this.onChange});

  @override
  State<KiloPriceBox> createState() => _KiloPriceBoxState();
}

class _KiloPriceBoxState extends State<KiloPriceBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width * 0.15,
      child: Column(
        children: [
          const Text(
            'سعر الكيلو',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: kLabelFontSize,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          TextBox(
            suffix: Text('\$'),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final regExp = RegExp(r'^\d*\.?\d{0,3}$');
                if (regExp.hasMatch(newValue.text)) {
                  return newValue;
                }
                return oldValue;
              }),
            ],
            controller: widget.controller,
            onChanged: (v) {
              widget.onChange(v);
            },
          ),
        ],
      ),
    );
  }
}

class TotalPriceBox extends StatefulWidget {
  final TextEditingController controller;
  final Function onChange;

  const TotalPriceBox(
      {super.key, required this.controller, required this.onChange});

  @override
  State<TotalPriceBox> createState() => _TotalPriceBoxState();
}

class _TotalPriceBoxState extends State<TotalPriceBox> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width * 0.15,
      child: Column(
        children: [
          const Text(
            'السعر الإجمالي',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: kLabelFontSize,
            ),
          ),
          SizedBox(
            height: 5,
          ),
          TextBox(
            suffix: Text('\$'),
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) {
                final regExp = RegExp(r'^\d*\.?\d{0,3}$');
                if (regExp.hasMatch(newValue.text)) {
                  return newValue;
                }
                return oldValue;
              }),
            ],
            controller: widget.controller,
            onChanged: (v) {
              widget.onChange(v);
            },
          ),
        ],
      ),
    );
  }
}
