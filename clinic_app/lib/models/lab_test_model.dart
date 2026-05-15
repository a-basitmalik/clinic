class LabTestModel {
  final int? id;
  final String testName;
  final String? instructions;

  const LabTestModel({this.id, required this.testName, this.instructions});

  factory LabTestModel.fromJson(Map<String, dynamic> j) => LabTestModel(
    id: j['id'] as int?,
    testName: j['test_name'] as String? ?? '',
    instructions: j['instructions'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'test_name': testName,
    'instructions': instructions,
  };
}
