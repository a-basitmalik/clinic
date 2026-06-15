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
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          height: 46,
          child: TextField(
            controller: _ctrl,
            onChanged: (v) {
              setState(() {});
              widget.onSearch(v);
            },
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  fontSize: 14, color: AppColors.textHint),
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 19, color: AppColors.textSecondary),
              suffixIcon: _ctrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 16, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _ctrl.clear();
                          widget.onSearch('');
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.glass,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.white, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),
        if (widget.filters != null) ...widget.filters!,
        if (widget.onAdd != null)
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onAdd,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 18,
                          color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        widget.addLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
