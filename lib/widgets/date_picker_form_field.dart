import 'package:flutter/material.dart';

class DatePickerFormField extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final void Function(DateTime) onDateSelected;
  final String? Function(DateTime?)? validator; // Add this line

  const DatePickerFormField({
    Key? key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.validator, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      validator: validator,
      builder: (FormFieldState<DateTime> state) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon: const Icon(Icons.calendar_today),
            errorText: state.errorText, // Add this line to show validation errors
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
                state.didChange(picked); // Add this line to update form state
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
      },
    );
  }
}