import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../services/places_service.dart';
import '../../../shared/utils/validators.dart';
import '../controllers/resume_builder_controller.dart';

/// Location field with Google Places autocomplete. As the user types a place
/// name, debounced suggestions appear below; tapping one fills the field.
/// Falls back to a plain validated text field when no Places key is configured.
class AddressField extends StatefulWidget {
  final ResumeBuilderController c;
  const AddressField(this.c, {super.key});

  @override
  State<AddressField> createState() => _AddressFieldState();
}

class _AddressFieldState extends State<AddressField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.c.location);
  final _focus = FocusNode();
  Timer? _debounce;
  List<String> _suggestions = const [];
  bool _loading = false;
  bool _suppress = false; // skip a fetch right after a selection

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String v) {
    widget.c.location = v;
    if (_suppress) {
      _suppress = false;
      return;
    }
    _debounce?.cancel();
    if (!PlacesService.instance.isEnabled || v.trim().length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetch(v));
  }

  Future<void> _fetch(String v) async {
    setState(() => _loading = true);
    final results = await PlacesService.instance.autocomplete(v);
    if (!mounted) return;
    setState(() {
      _loading = false;
      // Only show if the field still has focus and matches the latest text.
      _suggestions = (_focus.hasFocus && _ctrl.text == v) ? results : const [];
    });
  }

  void _select(String s) {
    _suppress = true;
    _ctrl.value = TextEditingValue(text: s, selection: TextSelection.collapsed(offset: s.length));
    widget.c.location = s;
    setState(() => _suggestions = const []);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ctrl,
          focusNode: _focus,
          decoration: InputDecoration(
            labelText: 'Location / address *',
            hintText: 'Start typing a city or place…',
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : const Icon(Icons.place_outlined, color: AppColors.textSecondary),
          ),
          validator: (v) => Validators.required(v, 'Location'),
          onChanged: _onChanged,
        ),
        if (_suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppRadii.input),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (final s in _suggestions.take(5))
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                    title: Text(s, style: const TextStyle(fontSize: 14)),
                    onTap: () => _select(s),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
