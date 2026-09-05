import unittest

from app.services.disease_risk_service import DiseaseRiskService


class DiseaseRiskServiceTests(unittest.TestCase):
    def test_all_demo_models_train_and_report_metrics(self):
        models = DiseaseRiskService.list_models()
        self.assertEqual(len(models), 4)
        self.assertEqual(
            {model["algorithm"] for model in models},
            {"LogisticRegression", "RandomForestClassifier", "DecisionTreeClassifier"},
        )
        self.assertTrue(all(0.5 <= model["accuracy"] <= 1 for model in models))

    def test_diabetes_prediction_returns_explainable_risk(self):
        result = DiseaseRiskService.predict(
            "diabetes",
            {"age": 58, "bmi": 34, "glucose": 185, "blood_pressure": 150, "family_history": 1},
        )
        self.assertIn(result["risk_level"], {"low", "moderate", "high"})
        self.assertGreaterEqual(result["risk_probability"], 0)
        self.assertLessEqual(result["risk_probability"], 1)
        self.assertIn("not be used to diagnose", result["safety_notice"])

    def test_prediction_validates_feature_ranges(self):
        with self.assertRaisesRegex(ValueError, "Glucose must be between"):
            DiseaseRiskService.predict(
                "diabetes",
                {"age": 58, "bmi": 34, "glucose": 900, "blood_pressure": 150, "family_history": 1},
            )


if __name__ == "__main__":
    unittest.main()
