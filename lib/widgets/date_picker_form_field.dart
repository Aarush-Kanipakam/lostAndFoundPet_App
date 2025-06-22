
import 'package:flutter/material.dart';
class DatePickerFormField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;

  const DatePickerFormField({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(2023),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(
            selectedDate == null
                ? 'Select a date'
                : '${selectedDate!.toLocal().toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 16,
              color: selectedDate == null ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
