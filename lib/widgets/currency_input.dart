import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';

class CurrencyInput extends StatefulWidget {
  final String label;
  final int initialValue;
  final ValueChanged<int> onChanged;
  final bool isRequired;

  const CurrencyInput({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  State<CurrencyInput> createState() => _CurrencyInputState();
}

class _CurrencyInputState extends State<CurrencyInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.initialValue > 0
          ? widget.initialValue.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isRequired ? '${widget.label} *' : widget.label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w500,
            ),
            hintText: '0',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12,
            ),
          ),
          onChanged: (val) {
            widget.onChanged(int.tryParse(val) ?? 0);
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
