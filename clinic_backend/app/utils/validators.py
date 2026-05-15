import re
from datetime import datetime
from datetime import date

_EMAIL_RE = re.compile(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')


def validate_email(email: str) -> bool:
    return bool(_EMAIL_RE.match((email or "").strip()))


def validate_required(data: dict, fields: list) -> dict:
    """Return {field: error_message} for every missing or blank field."""
    errors = {}
    for field in fields:
        val = data.get(field)
        if val is None or (isinstance(val, str) and not val.strip()):
            errors[field] = f"{field.replace('_', ' ').capitalize()} is required."
    return errors


def parse_time(time_str: str):
    """Parse 'HH:MM' string → datetime.time.  Returns None for blank input."""
    if not time_str or not str(time_str).strip():
        return None
    try:
        return datetime.strptime(str(time_str).strip(), "%H:%M").time()
    except ValueError:
        raise ValueError(f"Invalid time format '{time_str}'. Use HH:MM (e.g. 09:00).")


def parse_date(date_str: str) -> date:
    """Parse 'YYYY-MM-DD' → datetime.date. Returns None for blank input."""
    if not date_str or not str(date_str).strip():
        return None
    try:
        return datetime.strptime(str(date_str).strip(), "%Y-%m-%d").date()
    except ValueError:
        raise ValueError(f"Invalid date format '{date_str}'. Use YYYY-MM-DD (e.g. 2026-05-15).")


def parse_int(value, field_name: str, minimum: int = None) -> int:
    if value is None or (isinstance(value, str) and not value.strip()):
        return None
    try:
        iv = int(value)
    except (ValueError, TypeError):
        raise ValueError(f"{field_name} must be an integer.")
    if minimum is not None and iv < minimum:
        raise ValueError(f"{field_name} must be >= {minimum}.")
    return iv


def parse_float(value, field_name: str, minimum: float = None) -> float:
    if value is None or (isinstance(value, str) and not str(value).strip()):
        return None
    try:
        fv = float(value)
    except (ValueError, TypeError):
        raise ValueError(f"{field_name} must be a number.")
    if minimum is not None and fv < minimum:
        raise ValueError(f"{field_name} must be >= {minimum}.")
    return fv


def validate_clinic_registration(data: dict) -> dict:
    """
    Full validation of clinic registration payload.
    Returns an errors dict (empty = valid).
    """
    errors = {}

    # ── Clinic core fields ─────────────────────────────────────────────────
    errors.update(validate_required(data, [
        "clinic_name", "owner_name", "email", "phone",
        "clinic_type", "number_of_doctors",
    ]))

    clinic_email = (data.get("email") or "").lower().strip()
    if clinic_email and not validate_email(clinic_email):
        errors["email"] = "Invalid clinic email address."

    clinic_type = data.get("clinic_type")
    if clinic_type not in ("single_doctor", "multi_doctor"):
        errors["clinic_type"] = "clinic_type must be 'single_doctor' or 'multi_doctor'."

    try:
        num_doctors = int(data.get("number_of_doctors", 0))
    except (ValueError, TypeError):
        errors["number_of_doctors"] = "number_of_doctors must be an integer."
        num_doctors = 0

    if data.get("opening_time"):
        try:
            parse_time(data["opening_time"])
        except ValueError as exc:
            errors["opening_time"] = str(exc)

    if data.get("closing_time"):
        try:
            parse_time(data["closing_time"])
        except ValueError as exc:
            errors["closing_time"] = str(exc)

    # ── Doctors ────────────────────────────────────────────────────────────
    doctors = data.get("doctors")
    if not isinstance(doctors, list) or len(doctors) == 0:
        errors["doctors"] = "At least one doctor is required."
    else:
        if clinic_type == "single_doctor" and len(doctors) != 1:
            errors["doctors"] = "single_doctor clinic requires exactly 1 doctor."
        elif clinic_type == "multi_doctor" and num_doctors > 0 and len(doctors) != num_doctors:
            errors["doctors"] = (
                f"number_of_doctors is {num_doctors} but {len(doctors)} doctor(s) provided."
            )

        seen_doc_emails = set()
        for i, doc in enumerate(doctors):
            prefix = f"doctors[{i}]."
            for k, v in validate_required(doc, ["name", "email"]).items():
                errors[prefix + k] = v
            doc_email = (doc.get("email") or "").lower().strip()
            if doc_email:
                if not validate_email(doc_email):
                    errors[prefix + "email"] = "Invalid email address."
                elif doc_email in seen_doc_emails:
                    errors[prefix + "email"] = "Duplicate doctor email."
                else:
                    seen_doc_emails.add(doc_email)
            for tf in ("available_start_time", "available_end_time"):
                if doc.get(tf):
                    try:
                        parse_time(doc[tf])
                    except ValueError as exc:
                        errors[prefix + tf] = str(exc)

    # ── Receptionist ───────────────────────────────────────────────────────
    if data.get("has_receptionist"):
        recep = data.get("receptionist")
        if not recep or not isinstance(recep, dict):
            errors["receptionist"] = "Receptionist details required when has_receptionist is true."
        else:
            for k, v in validate_required(recep, ["name", "email"]).items():
                errors[f"receptionist.{k}"] = v
            r_email = (recep.get("email") or "").lower()
            if r_email and not validate_email(r_email):
                errors["receptionist.email"] = "Invalid receptionist email."

    # ── Pharmacy ───────────────────────────────────────────────────────────
    if data.get("has_pharmacy"):
        pharma = data.get("pharmacy")
        if not pharma or not isinstance(pharma, dict):
            errors["pharmacy"] = "Pharmacy details required when has_pharmacy is true."
        else:
            for k, v in validate_required(pharma, ["name", "email"]).items():
                errors[f"pharmacy.{k}"] = v
            p_email = (pharma.get("email") or "").lower()
            if p_email and not validate_email(p_email):
                errors["pharmacy.email"] = "Invalid pharmacy email."

    # ── Cross-entity duplicate email check ────────────────────────────────
    if not errors:
        seen_all = set()
        all_emails = []

        all_emails.append(("clinic admin", clinic_email))
        for i, doc in enumerate(doctors or []):
            all_emails.append((f"doctors[{i}]", (doc.get("email") or "").lower().strip()))
        if data.get("has_receptionist") and isinstance(data.get("receptionist"), dict):
            all_emails.append(("receptionist", (data["receptionist"].get("email") or "").lower()))
        if data.get("has_pharmacy") and isinstance(data.get("pharmacy"), dict):
            all_emails.append(("pharmacy", (data["pharmacy"].get("email") or "").lower()))

        for label, em in all_emails:
            if em and em in seen_all:
                errors["email_conflict"] = (
                    f"Email '{em}' appears more than once in the registration. "
                    "Each user must have a unique email."
                )
                break
            if em:
                seen_all.add(em)

    return errors
