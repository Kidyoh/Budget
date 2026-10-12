import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatters.dart';

/// Parses user-typed money, accepting thousands separators.
double? parseAmount(String? text) {
  if (text == null) return null;
  final cleaned = text.replaceAll(RegExp(r'[,\s]'), '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Shows [value] in a text field without a pointless `.0`.
String amountText(double? value) {
  if (value == null) return '';
  return value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);
}

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    required this.label,
    this.prefix,
    this.required = true,
    this.allowZero = false,
    this.max,
    this.helperText,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? prefix;
  final bool required;
  final bool allowZero;

  /// Upper bound with the message to show when it's exceeded.
  final (double, String)? max;
  final String? helperText;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        helperText: helperText,
      ),
      validator: (text) {
        final value = parseAmount(text);
        if (value == null) return required ? 'Enter an amount' : null;
        if (value < 0 || (!allowZero && value == 0)) {
          return 'Enter an amount above zero';
        }
        final limit = max;
        if (limit != null && value > limit.$1 + 0.005) return limit.$2;
        return null;
      },
    );
  }
}

/// A read-only field that opens a date picker.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.clearable = true,
    this.firstDate,
    this.icon = Icons.event_rounded,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool clearable;
  final DateTime? firstDate;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final date = value;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? now,
          firstDate: firstDate ?? DateTime(now.year - 5),
          lastDate: DateTime(now.year + 10),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: clearable && date != null
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => onChanged(null),
                )
              : null,
        ),
        isEmpty: date == null,
        child: date == null ? null : Text(formatLongDate(date)),
      ),
    );
  }
}

/// A row of selectable colour swatches.
class ColorSwatchPicker extends StatelessWidget {
  const ColorSwatchPicker({
    super.key,
    required this.colors,
    required this.selected,
    required this.onChanged,
    this.allowNone = false,
  });

  final List<int> colors;
  final int? selected;
  final ValueChanged<int?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget swatch(int? value) {
      final isSelected = value == selected;
      final color = value == null
          ? scheme.surfaceContainerHighest
          : Color(value);
      return Semantics(
        button: true,
        selected: isSelected,
        label: value == null ? 'No colour' : 'Colour',
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? scheme.onSurface : scheme.outlineVariant,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: value == null
                ? Icon(
                    Icons.block_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  )
                : isSelected
                ? Icon(
                    Icons.check_rounded,
                    size: 20,
                    color:
                        ThemeData.estimateBrightnessForColor(color) ==
                            Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  )
                : null,
          ),
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (allowNone) swatch(null),
        for (final c in colors) swatch(c),
      ],
    );
  }
}

/// Wraps a form in a scrollable bottom sheet that moves above the keyboard.
Future<T?> showFormSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: child,
      ),
    ),
  );
}
