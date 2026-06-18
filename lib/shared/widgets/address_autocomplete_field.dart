import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/places_service.dart';

/// A labelled address field with Google Places autocomplete. When no Places key
/// is configured it simply behaves as a normal text field (no suggestions).
/// Lives inside a Form, so [validator] participates in form validation.
class AddressAutocompleteField extends StatelessWidget {
  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final FormFieldValidator<String>? validator;
  final String? hint;

  const AddressAutocompleteField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.validator,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: initialValue),
              optionsBuilder: (value) async {
                if (value.text.trim().length < 3) return const Iterable<String>.empty();
                return PlacesService.instance.autocomplete(value.text);
              },
              onSelected: onChanged,
              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.next,
                  validator: validator,
                  onChanged: onChanged,
                  decoration: InputDecoration(
                    hintText: hint,
                    suffixIcon: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                  ),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(AppRadii.input),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 240, maxWidth: constraints.maxWidth),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final option = options.elementAt(i);
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, size: 18, color: AppColors.accent),
                            title: Text(option, style: const TextStyle(fontSize: 14)),
                            onTap: () => onSelected(option),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
