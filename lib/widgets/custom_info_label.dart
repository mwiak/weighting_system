import 'package:fluent_ui/fluent_ui.dart';

/// Custom InfoLabel Widget
/// 
/// A custom replacement for the Fluent UI InfoLabel widget that provides
/// consistent label styling and layout for form fields throughout the application.
/// 
/// Features:
/// - Consistent label typography and spacing
/// - Support for required field indicators
/// - Proper accessibility labeling
/// - RTL support for Arabic locale
/// - Customizable label styling
class CustomInfoLabel extends StatelessWidget {
  /// The label text to display above the child widget
  final String label;
  
  /// The child widget (typically a form input)
  final Widget child;
  
  /// Whether this field is required (shows * indicator)
  final bool isRequired;
  
  /// Custom label text style
  final TextStyle? labelStyle;
  
  /// Spacing between label and child widget
  final double spacing;
  
  const CustomInfoLabel({
    super.key,
    required this.label,
    required this.child,
    this.isRequired = false,
    this.labelStyle,
    this.spacing = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final defaultLabelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: theme.typography.body?.color,
    );
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: labelStyle ?? defaultLabelStyle,
            ),
            if (isRequired) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: (labelStyle?.fontSize ?? defaultLabelStyle.fontSize) ?? 14,
                  fontWeight: labelStyle?.fontWeight ?? defaultLabelStyle.fontWeight,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: spacing),
        child,
      ],
    );
  }
}

/// Extension methods for common form field patterns
extension CustomInfoLabelExtensions on CustomInfoLabel {
  /// Create an InfoLabel with TextFormBox
  static CustomInfoLabel textField({
    required String label,
    required TextEditingController controller,
    String? placeholder,
    bool isRequired = false,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return CustomInfoLabel(
      label: label,
      isRequired: isRequired,
      child: TextFormBox(
        controller: controller,
        placeholder: placeholder,
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLines: maxLines,
      ),
    );
  }

  /// Create an InfoLabel with ComboBox
  static CustomInfoLabel comboBox<T>({
    required String label,
    required T? value,
    required List<ComboBoxItem<T>> items,
    required void Function(T?) onChanged,
    bool isRequired = false,
    String? placeholder,
  }) {
    return CustomInfoLabel(
      label: label,
      isRequired: isRequired,
      child: ComboBox<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        placeholder: placeholder != null ? Text(placeholder) : null,
      ),
    );
  }

  /// Create an InfoLabel with DatePicker
  static CustomInfoLabel datePicker({
    required String label,
    required DateTime? selected,
    required void Function(DateTime) onChanged,
    bool isRequired = false,
  }) {
    return CustomInfoLabel(
      label: label,
      isRequired: isRequired,
      child: DatePicker(
        selected: selected,
        onChanged: onChanged,
      ),
    );
  }

  /// Create an InfoLabel with NumberBox
  static CustomInfoLabel numberField({
    required String label,
    required double? value,
    required void Function(double?) onChanged,
    bool isRequired = false,
    String? placeholder,
    double? min,
    double? max,
  }) {
    return CustomInfoLabel(
      label: label,
      isRequired: isRequired,
      child: NumberBox(
        value: value,
        onChanged: onChanged,
        placeholder: placeholder,
        min: min,
        max: max,
      ),
    );
  }
}