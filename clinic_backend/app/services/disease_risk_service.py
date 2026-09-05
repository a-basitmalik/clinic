from __future__ import annotations

from dataclasses import dataclass
from functools import lru_cache
from typing import Any
import warnings

import numpy as np
from sklearn.datasets import load_breast_cancer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.tree import DecisionTreeClassifier


SAFETY_NOTICE = (
    "Educational screening estimate only. This model is trained on a demonstration dataset "
    "and must not be used to diagnose, exclude disease, prescribe treatment, or replace "
    "clinical judgment and validated medical testing."
)


@dataclass(frozen=True)
class Feature:
    key: str
    label: str
    minimum: float
    maximum: float
    unit: str = ""
    description: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "key": self.key,
            "label": self.label,
            "min": self.minimum,
            "max": self.maximum,
            "unit": self.unit,
            "description": self.description,
        }


MODEL_DEFINITIONS = {
    "diabetes": {
        "name": "Diabetes Risk",
        "algorithm": "LogisticRegression",
        "features": [
            Feature("age", "Age", 1, 120, "years"),
            Feature("bmi", "BMI", 10, 70, "kg/m²"),
            Feature("glucose", "Glucose", 40, 400, "mg/dL"),
            Feature("blood_pressure", "Systolic Blood Pressure", 60, 260, "mmHg"),
            Feature("family_history", "Family History", 0, 1, "0=no, 1=yes"),
        ],
    },
    "heart_disease": {
        "name": "Heart Disease Risk",
        "algorithm": "RandomForestClassifier",
        "features": [
            Feature("age", "Age", 18, 120, "years"),
            Feature("sex", "Sex", 0, 1, "0=female, 1=male"),
            Feature("cholesterol", "Total Cholesterol", 80, 700, "mg/dL"),
            Feature("resting_bp", "Resting Systolic BP", 60, 260, "mmHg"),
            Feature("max_heart_rate", "Maximum Heart Rate", 40, 240, "bpm"),
            Feature("smoker", "Current Smoker", 0, 1, "0=no, 1=yes"),
        ],
    },
    "stroke": {
        "name": "Stroke Risk",
        "algorithm": "DecisionTreeClassifier",
        "features": [
            Feature("age", "Age", 1, 120, "years"),
            Feature("hypertension", "Hypertension", 0, 1, "0=no, 1=yes"),
            Feature("heart_disease", "Known Heart Disease", 0, 1, "0=no, 1=yes"),
            Feature("average_glucose", "Average Glucose", 40, 400, "mg/dL"),
            Feature("bmi", "BMI", 10, 70, "kg/m²"),
            Feature("smoker", "Current Smoker", 0, 1, "0=no, 1=yes"),
        ],
    },
    "breast_cancer": {
        "name": "Breast Cancer Screening Risk",
        "algorithm": "RandomForestClassifier",
        "features": [
            Feature("mean_radius", "Mean Radius", 5, 40),
            Feature("mean_texture", "Mean Texture", 5, 50),
            Feature("mean_perimeter", "Mean Perimeter", 30, 250),
            Feature("mean_area", "Mean Area", 100, 3000),
            Feature("mean_concavity", "Mean Concavity", 0, 0.5),
        ],
    },
}


class DiseaseRiskService:
    @staticmethod
    def list_models() -> list[dict[str, Any]]:
        trained = DiseaseRiskService._trained_models()
        return [
            DiseaseRiskService._model_metadata(key, trained[key]["accuracy"])
            for key in MODEL_DEFINITIONS
        ]

    @staticmethod
    def predict(model_key: str, inputs: dict[str, Any]) -> dict[str, Any]:
        definition = MODEL_DEFINITIONS.get(model_key)
        if not definition:
            raise ValueError("Unknown disease risk model.")

        values = []
        cleaned = {}
        for feature in definition["features"]:
            raw = inputs.get(feature.key)
            try:
                value = float(raw)
            except (TypeError, ValueError):
                raise ValueError(f"{feature.label} must be a number.")
            if not feature.minimum <= value <= feature.maximum:
                raise ValueError(
                    f"{feature.label} must be between {feature.minimum:g} and {feature.maximum:g}."
                )
            values.append(value)
            cleaned[feature.key] = value

        trained = DiseaseRiskService._trained_models()[model_key]
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", RuntimeWarning)
            probability = float(trained["model"].predict_proba([values])[0][1])
        risk_level = "low" if probability < 0.35 else "moderate" if probability < 0.70 else "high"
        return {
            "model": DiseaseRiskService._model_metadata(model_key, trained["accuracy"]),
            "risk_probability": round(probability, 4),
            "risk_percent": round(probability * 100, 1),
            "risk_level": risk_level,
            "inputs": cleaned,
            "safety_notice": SAFETY_NOTICE,
        }

    @staticmethod
    def _model_metadata(key: str, accuracy: float) -> dict[str, Any]:
        definition = MODEL_DEFINITIONS[key]
        return {
            "key": key,
            "name": definition["name"],
            "algorithm": definition["algorithm"],
            "accuracy": round(float(accuracy), 4),
            "accuracy_percent": round(float(accuracy) * 100, 1),
            "dataset": "deterministic educational demonstration dataset",
            "features": [feature.to_dict() for feature in definition["features"]],
            "safety_notice": SAFETY_NOTICE,
        }

    @staticmethod
    @lru_cache(maxsize=1)
    def _trained_models() -> dict[str, dict[str, Any]]:
        rng = np.random.default_rng(42)
        datasets = DiseaseRiskService._demo_datasets(rng)
        estimators = {
            "diabetes": make_pipeline(
                StandardScaler(),
                LogisticRegression(max_iter=1000, solver="liblinear", random_state=42),
            ),
            "heart_disease": RandomForestClassifier(n_estimators=160, max_depth=7, random_state=42),
            "stroke": DecisionTreeClassifier(max_depth=6, min_samples_leaf=8, random_state=42),
            "breast_cancer": RandomForestClassifier(n_estimators=180, max_depth=8, random_state=42),
        }
        trained = {}
        for key, (x, y) in datasets.items():
            x_train, x_test, y_train, y_test = train_test_split(
                x, y, test_size=0.25, random_state=42, stratify=y
            )
            model = estimators[key]
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", RuntimeWarning)
                model.fit(x_train, y_train)
                predictions = model.predict(x_test)
            trained[key] = {
                "model": model,
                "accuracy": accuracy_score(y_test, predictions),
            }
        return trained

    @staticmethod
    def _demo_datasets(rng: np.random.Generator) -> dict[str, tuple[np.ndarray, np.ndarray]]:
        n = 2200
        age = rng.uniform(18, 90, n)
        bmi = rng.uniform(17, 50, n)
        glucose = rng.uniform(65, 250, n)
        bp = rng.uniform(85, 200, n)
        family = rng.integers(0, 2, n)
        diabetes_score = (glucose - 125) / 28 + (bmi - 30) / 7 + (age - 50) / 22 + family * 1.1
        diabetes_y = (diabetes_score + rng.normal(0, 1.2, n) > 1.0).astype(int)

        sex = rng.integers(0, 2, n)
        cholesterol = rng.uniform(120, 400, n)
        resting_bp = rng.uniform(85, 210, n)
        max_hr = rng.uniform(70, 210, n)
        smoker = rng.integers(0, 2, n)
        heart_score = (
            (age - 52) / 18 + sex * 0.6 + (cholesterol - 220) / 75
            + (resting_bp - 135) / 35 - (max_hr - 145) / 45 + smoker * 0.9
        )
        heart_y = (heart_score + rng.normal(0, 1.3, n) > 1.1).astype(int)

        hypertension = rng.integers(0, 2, n)
        known_heart = rng.integers(0, 2, n)
        avg_glucose = rng.uniform(60, 280, n)
        stroke_bmi = rng.uniform(17, 48, n)
        stroke_smoker = rng.integers(0, 2, n)
        stroke_score = (
            (age - 62) / 14 + hypertension * 1.2 + known_heart * 1.3
            + (avg_glucose - 145) / 55 + (stroke_bmi - 32) / 10 + stroke_smoker * 0.7
        )
        stroke_y = (stroke_score + rng.normal(0, 1.4, n) > 2.0).astype(int)

        cancer = load_breast_cancer()
        indexes = [0, 1, 2, 3, 6]
        breast_x = cancer.data[:, indexes]
        breast_y = (cancer.target == 0).astype(int)  # 1 means malignant/high risk
        return {
            "diabetes": (np.column_stack([age, bmi, glucose, bp, family]), diabetes_y),
            "heart_disease": (
                np.column_stack([age, sex, cholesterol, resting_bp, max_hr, smoker]),
                heart_y,
            ),
            "stroke": (
                np.column_stack([age, hypertension, known_heart, avg_glucose, stroke_bmi, stroke_smoker]),
                stroke_y,
            ),
            "breast_cancer": (breast_x, breast_y),
        }
