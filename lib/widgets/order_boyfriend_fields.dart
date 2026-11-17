import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:period_tracker/theme.dart';

/// Phone and message inputs for the Order boyfriend sheet.
/// Owns its controllers so they outlive the sheet's exit animation.
class OrderBoyfriendFields extends StatefulWidget {
  final String initialIsoCode;
  final String initialNumber;
  final void Function(String isoCode, String dialCode, String number) onPhoneChanged;
  final ValueChanged<String> onMessageChanged;

  const OrderBoyfriendFields({
    super.key,
    required this.initialIsoCode,
    required this.initialNumber,
    required this.onPhoneChanged,
    required this.onMessageChanged,
  });

  @override
  State<OrderBoyfriendFields> createState() => _OrderBoyfriendFieldsState();
}

class _OrderBoyfriendFieldsState extends State<OrderBoyfriendFields> {
  late final TextEditingController _phone = TextEditingController(text: widget.initialNumber);
  final TextEditingController _message = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IntlPhoneField(
          controller: _phone,
          // The package always shows an "8/8" counter; collapse it, keep the length limit.
          decoration: const InputDecoration(hintText: 'Phone number', counterStyle: TextStyle(fontSize: 0, height: 0)),
          style: context.text.bodyLarge,
          dropdownTextStyle: context.text.bodyLarge,
          initialCountryCode: widget.initialIsoCode,
          onCountryChanged: (country) => widget.onPhoneChanged(country.code, '+${country.fullCountryCode}', _phone.text),
          onChanged: (phone) => widget.onPhoneChanged(phone.countryISOCode, phone.countryCode, phone.number),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _message,
          decoration: const InputDecoration(hintText: 'Message'),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          onChanged: widget.onMessageChanged,
        ),
      ],
    );
  }
}
