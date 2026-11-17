import 'package:flutter/material.dart';
import 'package:period_tracker/theme.dart';
import 'package:period_tracker/widgets/pressable.dart';
import 'package:period_tracker/widgets/primary_button.dart';

/// Sheet inputs need their own fill and border; the global fill equals the sheet colour.
InputDecorationTheme _sheetInputs(AppColors c) {
  OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(color: color, width: width),
  );
  return InputDecorationTheme(
    filled: true,
    fillColor: c.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    hintStyle: TextStyle(fontFamily: 'Inter', fontSize: 17, color: c.labelTertiary),
    border: border(c.hairline, 1),
    enabledBorder: border(c.hairline, 1),
    focusedBorder: border(c.accent, 2),
  );
}

/// The app's one modal surface: a bottom panel kept clear of the system navigation bar.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  String? title,
  String? message,
  required Widget Function(BuildContext context) builder,
  String? actionLabel,
  VoidCallback? onAction,
  bool closeOnAction = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.colors.card,
    builder: (sheetContext) {
      final c = sheetContext.colors;
      return Theme(
        data: Theme.of(sheetContext).copyWith(inputDecorationTheme: _sheetInputs(c)),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
          // useSafeArea covers only the top; SafeArea handles the nav bar (0 when the keyboard is open).
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 5,
                        decoration: BoxDecoration(color: c.hairline, borderRadius: BorderRadius.circular(99)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (title != null) Text(title, style: sheetContext.text.titleLarge),
                    if (message != null) ...[const SizedBox(height: 6), Text(message, style: sheetContext.text.bodyMedium?.copyWith(color: c.labelSecondary))],
                    if (title != null || message != null) const SizedBox(height: 20),
                    builder(sheetContext),
                    if (actionLabel != null) ...[
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: actionLabel,
                        onPressed: () {
                          onAction?.call();
                          if (closeOnAction) Navigator.of(sheetContext).pop();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Confirmation panel, for destructive or irreversible actions.
Future<bool> showConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) async {
  final bool? result = await showAppSheet<bool>(
    context: context,
    title: title,
    message: message,
    builder: (sheetContext) => Column(
      children: [
        PrimaryButton(
          label: confirmLabel,
          style: destructive ? AppButtonStyle.danger : AppButtonStyle.primary,
          onPressed: () => Navigator.of(sheetContext).pop(true),
        ),
        const SizedBox(height: 8),
        PrimaryButton(label: cancelLabel, style: AppButtonStyle.quiet, onPressed: () => Navigator.of(sheetContext).pop(false)),
      ],
    ),
  );
  return result ?? false;
}

/// Centred dialog, for prompts that interrupt (for example a permission request on first launch)
/// instead of following something the user just tapped.
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: TextButton.styleFrom(foregroundColor: dialogContext.colors.accent),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showInfo({required BuildContext context, required String title, required String message, String buttonLabel = 'OK'}) {
  return showAppSheet<void>(
    context: context,
    title: title,
    message: message,
    builder: (sheetContext) => PrimaryButton(label: buttonLabel, onPressed: () => Navigator.of(sheetContext).pop()),
  );
}

class SelectOption<T> {
  final T value;
  final String label;
  final IconData? icon;
  const SelectOption({required this.value, required this.label, this.icon});
}

/// Pick one item from a list. Returns the value, or null if dismissed.
Future<T?> showSelectSheet<T>({
  required BuildContext context,
  required String title,
  String? message,
  required List<SelectOption<T>> options,
  required T selected,
}) {
  return showAppSheet<T>(
    context: context,
    title: title,
    message: message,
    builder: (sheetContext) {
      final c = sheetContext.colors;
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.55;
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: ColoredBox(
            color: c.background,
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: options.length,
              separatorBuilder: (_, _) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Divider(height: 0.5, thickness: 0.5, color: c.hairline),
              ),
              itemBuilder: (context, i) {
                final SelectOption<T> o = options[i];
                final bool isSelected = o.value == selected;
                return Pressable(
                  pressedScale: 0.99,
                  onTap: () => Navigator.of(sheetContext).pop(o.value),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          if (o.icon != null) ...[Icon(o.icon, size: 20, color: isSelected ? c.label : c.labelSecondary), const SizedBox(width: 12)],
                          Expanded(
                            child: Text(o.label, style: context.text.bodyLarge?.copyWith(fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
                          ),
                          if (isSelected) Icon(Icons.check_rounded, size: 22, color: c.label),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
    },
  );
}

/// 24-hour time wheel in a panel. Returns the time, or null if dismissed.
/// The platform's own time picker (Material dial on Android), in 24-hour format like the rest of the app.
/// [message] is unused: the picker has no room for it, [title] becomes its heading.
Future<TimeOfDay?> showTimeSheet({required BuildContext context, required String title, String? message, required TimeOfDay initial}) {
  return showTimePicker(
    context: context,
    initialTime: initial,
    helpText: title,
    builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
  );
}

/// Single text field in a sheet. Returns the entered text, or null if dismissed.
Future<String?> showTextSheet({
  required BuildContext context,
  required String title,
  String? message,
  String initial = '',
  String? hint,
  int maxLines = 1,
  TextCapitalization capitalization = TextCapitalization.sentences,
  String actionLabel = 'Save',
}) async {
  String text = initial;
  bool saved = false;
  await showAppSheet<void>(
    context: context,
    title: title,
    message: message,
    actionLabel: actionLabel,
    onAction: () => saved = true,
    builder: (_) => _TextSheetField(initial: initial, hint: hint, maxLines: maxLines, capitalization: capitalization, onChanged: (value) => text = value),
  );
  return saved ? text : null;
}

/// Owns the controller so it outlives the sheet's exit animation.
class _TextSheetField extends StatefulWidget {
  final String initial;
  final String? hint;
  final int maxLines;
  final TextCapitalization capitalization;
  final ValueChanged<String> onChanged;

  const _TextSheetField({required this.initial, required this.hint, required this.maxLines, required this.capitalization, required this.onChanged});

  @override
  State<_TextSheetField> createState() => _TextSheetFieldState();
}

class _TextSheetFieldState extends State<_TextSheetField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: true,
      maxLines: widget.maxLines,
      minLines: widget.maxLines > 1 ? 3 : 1,
      textCapitalization: widget.capitalization,
      decoration: InputDecoration(hintText: widget.hint),
      onChanged: widget.onChanged,
    );
  }
}
