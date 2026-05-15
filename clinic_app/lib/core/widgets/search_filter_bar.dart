import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class SearchFilterBar extends StatefulWidget {
  final String hint;
  final void Function(String) onSearch;
  final List<Widget>? filters;
  final VoidCallback? onAdd;
  final String addLabel;

  const SearchFilterBar({
    super.key,
    required this.hint,
    required this.onSearch,
    this.filters,
    this.onAdd,
    this.addLabel = 'Add',
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 44,
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onSearch,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(fontSize: 14, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textSecondary),
                      onPressed: () { setState(() { _ctrl.clear(); widget.onSearch(''); }); },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        if (widget.filters != null) ...widget.filters!,
        if (widget.onAdd != null)
          ElevatedButton.icon(
            onPressed: widget.onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(widget.addLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
