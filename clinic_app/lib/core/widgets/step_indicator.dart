import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int totalSteps;
  final int currentStep;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.totalSteps,
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < totalSteps; i++) ...[
          _StepNode(
            index: i,
            isCompleted: i < currentStep,
            isCurrent:   i == currentStep,
            label:       labels.length > i ? labels[i] : '${i + 1}',
          ),
          if (i < totalSteps - 1)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  height: 2,
                  color: i < currentStep ? AppColors.primary : AppColors.border,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepNode extends StatelessWidget {
  final int    index;
  final bool   isCompleted;
  final bool   isCurrent;
  final String label;

  const _StepNode({
    required this.index,
    required this.isCompleted,
    required this.isCurrent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final Color fill = isCompleted || isCurrent ? AppColors.primary : Colors.transparent;
    final Color border = isCompleted || isCurrent ? AppColors.primary : AppColors.border;
    final Color textColor = isCurrent
        ? Colors.white
        : isCompleted
            ? Colors.white
            : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border, width: 2),
            shape: BoxShape.circle,
          ),
          child: isCompleted
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 56,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: isCurrent ? AppColors.primary : AppColors.textSecondary,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
