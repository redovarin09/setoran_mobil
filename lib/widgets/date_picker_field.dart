import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/constants/app_colors.dart';

class DatePickerField extends StatefulWidget {
  final String label;
  final DateTime initialDate;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerField({
    super.key,
    required this.label,
    required this.initialDate,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  @override
  State<DatePickerField> createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late DateTime _selected;
  final _fmt = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: widget.firstDate ?? DateTime(2020),
      lastDate: widget.lastDate ?? DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selected = picked);
      widget.onChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _pick,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  _fmt.format(_selected),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down,
                    color: AppColors.textLight),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}
