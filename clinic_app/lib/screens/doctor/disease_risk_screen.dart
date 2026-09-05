import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/clinical_ai_service.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/premium_surface.dart';
import '../../core/widgets/responsive_layout.dart';
import '../../models/api_response_model.dart';
import '../../routes/app_routes.dart';

class DiseaseRiskScreen extends StatefulWidget {
  const DiseaseRiskScreen({super.key});

  @override
  State<DiseaseRiskScreen> createState() => _DiseaseRiskScreenState();
}

class _DiseaseRiskScreenState extends State<DiseaseRiskScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  List<Map<String, dynamic>> _models = [];
  Map<String, dynamic>? _selected;
  Map<String, dynamic>? _result;
  bool _loading = true;
  bool _predicting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadModels() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _models = await ClinicalAiService.riskModels();
      if (_models.isNotEmpty) _selectModel(_models.first);
      if (mounted) setState(() => _loading = false);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message;
          _loading = false;
        });
      }
    }
  }

  void _selectModel(Map<String, dynamic> model) {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    for (final feature in _features(model)) {
      _controllers[feature['key'] as String] = TextEditingController();
    }
    setState(() {
      _selected = model;
      _result = null;
    });
  }

  List<Map<String, dynamic>> _features(Map<String, dynamic>? model) {
    return ((model?['features'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _predict() async {
    if (!_formKey.currentState!.validate() || _selected == null) return;
    setState(() => _predicting = true);
    try {
      final inputs = <String, dynamic>{
        for (final entry in _controllers.entries)
          entry.key: double.parse(entry.value.text.trim()),
      };
      final result = await ClinicalAiService.predictDiseaseRisk(
        _selected!['key'] as String,
        inputs,
      );
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _predicting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      title: 'Disease Risk',
      currentRoute: AppRoutes.diseaseRisk,
      body: _loading
          ? const LoadingWidget()
          : _error != null
              ? ErrorView(message: _error!, onRetry: _loadModels)
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _notice(),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _models
              .map(
                (model) => ChoiceChip(
                  selected: _selected?['key'] == model['key'],
                  label: Text(model['name'] as String),
                  avatar: const Icon(Icons.analytics_rounded, size: 18),
                  onSelected: (_) => _selectModel(model),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        if (_selected != null) _modelForm(),
        if (_result != null) ...[
          const SizedBox(height: 18),
          _resultCard(),
        ],
      ],
    );
  }

  Widget _notice() {
    return GlassPanel(
      radius: 18,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.science_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Educational scikit-learn screening',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _selected?['safety_notice'] as String? ??
                        'These models demonstrate predictive analytics and are not validated diagnostic tools.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelForm() {
    final model = _selected!;
    final features = _features(model);
    return GlassPanel(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model['name'] as String,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                '${model['algorithm']} · test accuracy ${model['accuracy_percent']}%',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 360,
                  mainAxisExtent: 84,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 12,
                ),
                itemCount: features.length,
                itemBuilder: (_, index) => _featureField(features[index]),
              ),
              const SizedBox(height: 14),
              CustomButton(
                label: 'Calculate Risk',
                icon: Icons.model_training_rounded,
                loading: _predicting,
                onPressed: _predict,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureField(Map<String, dynamic> feature) {
    final key = feature['key'] as String;
    final min = feature['min'] as num;
    final max = feature['max'] as num;
    final unit = feature['unit'] as String? ?? '';
    return TextFormField(
      controller: _controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: feature['label'] as String,
        helperText: '$min–$max${unit.isEmpty ? '' : ' · $unit'}',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final parsed = double.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number';
        if (parsed < min || parsed > max)
          return 'Must be between $min and $max';
        return null;
      },
    );
  }

  Widget _resultCard() {
    final level = _result!['risk_level'] as String? ?? 'unknown';
    final color = level == 'high'
        ? AppColors.danger
        : level == 'moderate'
            ? AppColors.warning
            : AppColors.success;
    return GlassPanel(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.monitor_heart_rounded, color: color, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_result!['risk_percent']}% ${level.toUpperCase()} risk',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (_result!['risk_probability'] as num).toDouble(),
              minHeight: 12,
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 14),
            Text(
              _result!['safety_notice'] as String,
              style:
                  const TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
