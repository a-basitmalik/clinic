# Clinic Management System — Backend

Flask + MySQL REST API backend for the Clinic Management System.

- **Flask API port:** 5110
- **Public base URL:** `https://clinic.nalexustechnologies.com/api`
- **Internal URL:** `http://127.0.0.1:5110`

---

## Requirements

- Python 3.10+
- MySQL 8.0+
- Ubuntu/Linux server (production)

---

## Local Setup

```bash
# 1. Enter project directory
cd /home/nalexus/clinic/clinic_backend

# 2. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Configure environment
cp .env.example .env
nano .env    # Set SECRET_KEY, JWT_SECRET_KEY, DB_PASSWORD
```

### MySQL — one-time setup

```sql
CREATE DATABASE IF NOT EXISTS clinic
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'clinic'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON clinic.* TO 'clinic'@'localhost';
FLUSH PRIVILEGES;
```

### Import schema and seed data

```bash
mysql -u clinic -p clinic < migrations/schema.sql
```

### Run Flask-Migrate (alternative to raw SQL)

```bash
export FLASK_APP=run.py
flask db init          # first time only
flask db migrate -m "initial schema"
flask db upgrade
```

### Create the first Super Admin

```bash
export FLASK_APP=run.py
flask create-super-admin
# prompts: email / password / name
```

### Start the server

```bash
# Development
python run.py

# Production (Gunicorn)
pip install gunicorn
gunicorn -w 4 -b 0.0.0.0:5110 "run:app"
```

---

## Production Deployment (Ubuntu + Nginx)

### Firewall

```bash
sudo ufw allow 5110
```

### Nginx reverse-proxy

Add inside the server block at `/etc/nginx/sites-available/default`:

```nginx
location /api/ {
    proxy_pass         http://127.0.0.1:5110;
    proxy_set_header   Host              $host;
    proxy_set_header   X-Real-IP         $remote_addr;
    proxy_set_header   X-Forwarded-For   $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
}
```

```bash
sudo nginx -t && sudo systemctl reload nginx
```

---

## API Reference

All endpoints are prefixed with `/api`.  
Authenticated endpoints require: `Authorization: Bearer <token>`

### Response envelope

```json
// Success
{ "success": true,  "message": "...", "data": {} }

// Error
{ "success": false, "message": "...", "errors": {} }

// Paginated
{ "success": true, "message": "...", "data": [], "pagination": { "page":1, "per_page":20, "total":100, "pages":5 } }
```

---

### Health

| Method | Endpoint | Auth |
|--------|----------|------|
| GET | `/api/health` | None |

```bash
curl https://clinic.nalexustechnologies.com/api/health
```

---

### Authentication

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/auth/login` | None | Login |
| GET | `/api/auth/me` | Bearer | Current user |
| POST | `/api/auth/change-password` | Bearer | Change password |
| POST | `/api/auth/refresh` | Refresh token | New access token |
| POST | `/api/auth/logout` | Bearer | Logout |

#### Login

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@clinic.com",
    "password": "MyPassword123!"
  }'
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR...",
    "user": {
      "id": 1,
      "name": "Dr. Admin",
      "email": "admin@clinic.com",
      "role": "clinic_admin",
      "clinic_id": 1,
      "doctor_id": null,
      "status": "active",
      "must_change_password": true
    }
  }
}
```

#### Change Password

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/auth/change-password \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "old_password": "TempPass1!",
    "new_password": "NewSecurePass99!"
  }'
```

---

### Clinic Registration & Management

| Method | Endpoint | Auth | Role |
|--------|----------|------|------|
| POST | `/api/clinics/register` | None | Public |
| GET | `/api/clinics` | Bearer | super_admin |
| GET | `/api/clinics/<id>` | Bearer | super_admin / same clinic |
| PUT | `/api/clinics/<id>` | Bearer | super_admin / clinic_admin |
| PUT | `/api/clinics/<id>/approve` | Bearer | super_admin |
| PUT | `/api/clinics/<id>/suspend` | Bearer | super_admin |
| PUT | `/api/clinics/<id>/unsuspend` | Bearer | super_admin |

#### Register a single-doctor clinic

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/clinics/register \
  -H "Content-Type: application/json" \
  -d '{
    "clinic_name": "City Health Clinic",
    "owner_name": "Dr. Sara Khan",
    "email": "sara@cityhealthclinic.com",
    "phone": "0300-1234567",
    "address": "123 Main Street, Block 4",
    "city": "Karachi",
    "clinic_type": "single_doctor",
    "number_of_doctors": 1,
    "has_pharmacy": true,
    "has_receptionist": true,
    "opening_time": "09:00",
    "closing_time": "17:00",
    "working_days": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
    "doctors": [
      {
        "name": "Dr. Sara Khan",
        "email": "doctor.sara@cityhealthclinic.com",
        "phone": "0300-9876543",
        "department": "General Medicine",
        "specialization": "General Practitioner",
        "qualification": "MBBS",
        "experience": 8,
        "license_number": "PMDC-45678",
        "consultation_fee": 800,
        "available_days": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
        "available_start_time": "09:00",
        "available_end_time": "14:00"
      }
    ],
    "receptionist": {
      "name": "Ayesha Malik",
      "email": "receptionist@cityhealthclinic.com",
      "phone": "0300-1111222"
    },
    "pharmacy": {
      "name": "Bilal Ahmed",
      "email": "pharmacy@cityhealthclinic.com",
      "phone": "0300-3334444"
    }
  }'
```

**Response (201):**
```json
{
  "success": true,
  "message": "Clinic registered successfully. Your application is under review...",
  "data": {
    "clinic": {
      "id": 1,
      "clinic_name": "City Health Clinic",
      "status": "pending",
      ...
    },
    "created_accounts": {
      "clinic_admin": {
        "name": "Dr. Sara Khan",
        "email": "sara@cityhealthclinic.com",
        "role": "clinic_admin",
        "temp_password": "Xk9mR!2w"
      },
      "doctors": [
        {
          "name": "Dr. Sara Khan",
          "email": "doctor.sara@cityhealthclinic.com",
          "role": "doctor",
          "specialization": "General Practitioner",
          "department": "General Medicine",
          "temp_password": "Qz4nT#7p"
        }
      ],
      "receptionist": {
        "name": "Ayesha Malik",
        "email": "receptionist@cityhealthclinic.com",
        "role": "receptionist",
        "temp_password": "Lp5vY@8s"
      },
      "pharmacy": {
        "name": "Bilal Ahmed",
        "email": "pharmacy@cityhealthclinic.com",
        "role": "pharmacy",
        "temp_password": "Mn2kJ$6r"
      }
    },
    "note": "All passwords are temporary. Users will be prompted to change them on first login."
  }
}
```

#### Approve a clinic (super_admin)

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/clinics/1/approve \
  -H "Authorization: Bearer <super_admin_token>"
```

#### Suspend a clinic (super_admin)

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/clinics/1/suspend \
  -H "Authorization: Bearer <super_admin_token>"
```

#### List all clinics with pagination (super_admin)

```bash
curl "https://clinic.nalexustechnologies.com/api/clinics?page=1&per_page=10&status=pending" \
  -H "Authorization: Bearer <super_admin_token>"
```

---

### Super Admin

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/super-admin/dashboard` | Bearer super_admin | Key metrics |
| GET | `/api/super-admin/clinics/pending` | Bearer super_admin | Pending clinic queue |
| GET | `/api/super-admin/stats` | Bearer super_admin | Role/type/status breakdowns |
| GET | `/api/super-admin/revenue` | Bearer super_admin | Revenue by type & method |

#### Dashboard

```bash
curl https://clinic.nalexustechnologies.com/api/super-admin/dashboard \
  -H "Authorization: Bearer <super_admin_token>"
```

**Response:**
```json
{
  "success": true,
  "message": "Dashboard data retrieved.",
  "data": {
    "total_clinics": 12,
    "active_clinics": 8,
    "pending_clinics": 3,
    "suspended_clinics": 1,
    "total_doctors": 24,
    "total_patients": 310,
    "total_system_revenue": 150000.00
  }
}
```

---

### Clinic Admin (Phase 4)

All endpoints below require an **approved clinic** and a `clinic_admin` token.

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/api/clinic-admin/dashboard` | Bearer clinic_admin | Clinic dashboard metrics |
| GET | `/api/clinic-admin/revenue` | Bearer clinic_admin | Clinic revenue summary |
| GET | `/api/clinic-admin/reports` | Bearer clinic_admin | Export-ready report JSON |
| GET | `/api/clinic-admin/patients` | Bearer clinic_admin | Patients list (paginated) |
| GET | `/api/clinic-admin/appointments` | Bearer clinic_admin | Appointments list (paginated + filters) |

#### Clinic Admin dashboard

```bash
curl https://clinic.nalexustechnologies.com/api/clinic-admin/dashboard \
  -H "Authorization: Bearer <clinic_admin_token>"
```

#### Revenue summary

```bash
curl https://clinic.nalexustechnologies.com/api/clinic-admin/revenue \
  -H "Authorization: Bearer <clinic_admin_token>"
```

#### Reports (date range + optional doctor_id)

```bash
curl "https://clinic.nalexustechnologies.com/api/clinic-admin/reports?start_date=2026-05-01&end_date=2026-05-15&doctor_id=1" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

#### Patients list (pagination + search)

```bash
curl "https://clinic.nalexustechnologies.com/api/clinic-admin/patients?page=1&per_page=20&q=Ali" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

#### Appointments list (filters)

```bash
curl "https://clinic.nalexustechnologies.com/api/clinic-admin/appointments?page=1&per_page=20&status=waiting&doctor_id=1&date=2026-05-15" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

---

### Departments (Clinic Admin)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/departments` | Bearer clinic_admin | Create department |
| GET | `/api/departments` | Bearer clinic_admin | List departments |
| GET | `/api/departments/<id>` | Bearer clinic_admin | Get department |
| PUT | `/api/departments/<id>` | Bearer clinic_admin | Update department |
| DELETE | `/api/departments/<id>` | Bearer clinic_admin | Soft delete department |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/departments \
  -H "Authorization: Bearer <clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Cardiology","description":"Heart & vascular care","status":"active"}'
```

---

### Doctors (Clinic Admin)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/doctors` | Bearer clinic_admin | Create doctor + login |
| GET | `/api/doctors` | Bearer clinic_admin | List doctors |
| GET | `/api/doctors/<id>` | Bearer clinic_admin | Get doctor |
| PUT | `/api/doctors/<id>` | Bearer clinic_admin | Update doctor |
| PUT | `/api/doctors/<id>/deactivate` | Bearer clinic_admin | Deactivate doctor + user |
| DELETE | `/api/doctors/<id>` | Bearer clinic_admin | Soft delete doctor + user |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/doctors \
  -H "Authorization: Bearer <clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Dr. Kamran",
    "email":"dr.kamran@clinic.com",
    "phone":"0300-1111222",
    "department_id": 1,
    "specialization":"Cardiology",
    "qualification":"MBBS, FCPS",
    "experience": 6,
    "license_number":"PMDC-9999",
    "consultation_fee": 1500,
    "available_days":["Monday","Wednesday"],
    "available_start_time":"10:00",
    "available_end_time":"14:00"
  }'
```

```bash
curl https://clinic.nalexustechnologies.com/api/doctors \
  -H "Authorization: Bearer <clinic_admin_token>"
```

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/doctors/1/deactivate \
  -H "Authorization: Bearer <clinic_admin_token>"
```

---

### Receptionists (Clinic Admin)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/receptionists` | Bearer clinic_admin | Create receptionist + login |
| GET | `/api/receptionists` | Bearer clinic_admin | List receptionists |
| GET | `/api/receptionists/<id>` | Bearer clinic_admin | Get receptionist |
| PUT | `/api/receptionists/<id>` | Bearer clinic_admin | Update receptionist |
| DELETE | `/api/receptionists/<id>` | Bearer clinic_admin | Soft delete receptionist |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/receptionists \
  -H "Authorization: Bearer <clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Ayesha","email":"ayesha.recep@clinic.com","phone":"0300-2222333"}'
```

---

### Pharmacy Users (Clinic Admin)

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| POST | `/api/pharmacy/users` | Bearer clinic_admin | Create pharmacy user + login |
| GET | `/api/pharmacy/users` | Bearer clinic_admin | List pharmacy users |
| GET | `/api/pharmacy/users/<id>` | Bearer clinic_admin | Get pharmacy user |
| PUT | `/api/pharmacy/users/<id>` | Bearer clinic_admin | Update pharmacy user |
| DELETE | `/api/pharmacy/users/<id>` | Bearer clinic_admin | Soft delete pharmacy user |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/pharmacy/users \
  -H "Authorization: Bearer <clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{"name":"Bilal","email":"bilal.pharmacy@clinic.com","phone":"0300-3333444"}'
```

---

## Phase 5 — Patients, Appointments, Tokens, Payments

### Patients

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/api/patients` | Bearer | receptionist, clinic_admin |
| GET | `/api/patients` | Bearer | receptionist, clinic_admin, doctor |
| GET | `/api/patients/<id>` | Bearer | receptionist, clinic_admin, doctor, patient |
| PUT | `/api/patients/<id>` | Bearer | receptionist, clinic_admin |
| GET | `/api/patients/<id>/history` | Bearer | receptionist, clinic_admin, doctor, patient |

#### Create patient

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/patients \
  -H "Authorization: Bearer <receptionist_or_clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Ali Raza",
    "age": 30,
    "gender":"male",
    "phone":"0300-5555555",
    "cnic":"42101-1234567-1",
    "address":"Karachi",
    "blood_group":"B+",
    "emergency_contact":"0300-9999999"
  }'
```

#### List patients (pagination + search)

```bash
curl "https://clinic.nalexustechnologies.com/api/patients?page=1&per_page=20&q=Ali&gender=male" \
  -H "Authorization: Bearer <token>"
```

#### Patient history

```bash
curl https://clinic.nalexustechnologies.com/api/patients/1/history \
  -H "Authorization: Bearer <token>"
```

---

### Appointments (Token Queue)

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/api/appointments` | Bearer | receptionist, clinic_admin |
| GET | `/api/appointments` | Bearer | receptionist, clinic_admin, doctor |
| GET | `/api/appointments/today` | Bearer | receptionist, clinic_admin, doctor |
| GET | `/api/appointments/doctor/<doctor_id>` | Bearer | receptionist, clinic_admin, doctor |
| GET | `/api/appointments/<id>` | Bearer | receptionist, clinic_admin, doctor |
| PUT | `/api/appointments/<id>/status` | Bearer | receptionist, clinic_admin, doctor, assistant |
| PUT | `/api/appointments/<id>/cancel` | Bearer | receptionist, clinic_admin |
| PUT | `/api/appointments/<id>/reschedule` | Bearer | receptionist, clinic_admin |

#### Book appointment (auto token)

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/appointments \
  -H "Authorization: Bearer <receptionist_or_clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "doctor_id": 1,
    "appointment_date": "2026-05-15",
    "appointment_time": "11:30",
    "consultation_type": "new",
    "fee": 1500,
    "payment_status": "paid",
    "paid_amount": 1500,
    "payment_method": "cash"
  }'
```

#### Today appointments

```bash
curl https://clinic.nalexustechnologies.com/api/appointments/today \
  -H "Authorization: Bearer <token>"
```

#### Doctor queue (default today, or provide date)

```bash
curl "https://clinic.nalexustechnologies.com/api/appointments/doctor/1?date=2026-05-15" \
  -H "Authorization: Bearer <token>"
```

#### Update appointment status

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/appointments/1/status \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"status":"in_consultation"}'
```

#### Cancel appointment

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/appointments/1/cancel \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"reason":"Patient not available"}'
```

#### Reschedule appointment

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/appointments/1/reschedule \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"appointment_date":"2026-05-16","appointment_time":"12:00"}'
```

---

### Payments

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/api/payments` | Bearer | receptionist, clinic_admin (consultation), pharmacy (pharmacy) |
| GET | `/api/payments` | Bearer | receptionist, clinic_admin, doctor |
| GET | `/api/payments/patient/<patient_id>` | Bearer | receptionist, clinic_admin, doctor, patient |
| GET | `/api/payments/revenue-summary` | Bearer | receptionist, clinic_admin |

#### Create payment

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/payments \
  -H "Authorization: Bearer <receptionist_or_clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "appointment_id": 1,
    "payment_type": "consultation",
    "amount": 1500,
    "method": "cash",
    "status": "paid"
  }'
```

#### Patient payments

```bash
curl https://clinic.nalexustechnologies.com/api/payments/patient/1 \
  -H "Authorization: Bearer <token>"
```

#### Revenue summary

```bash
curl "https://clinic.nalexustechnologies.com/api/payments/revenue-summary?start_date=2026-05-01&end_date=2026-05-15" \
  -H "Authorization: Bearer <token>"
```

---

### Receptionist Dashboard

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| GET | `/api/receptionists/dashboard` | Bearer | receptionist, clinic_admin |

```bash
curl https://clinic.nalexustechnologies.com/api/receptionists/dashboard \
  -H "Authorization: Bearer <token>"
```

---

## Phase 6 — Doctor Workflow, Consultation, Prescriptions, Assistants

### Doctor Workflow

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| GET | `/api/doctors/dashboard` | Bearer | doctor |
| GET | `/api/doctors/today-appointments` | Bearer | doctor |
| GET | `/api/doctors/queue` | Bearer | doctor |
| GET | `/api/doctors/patients/<patient_id>/profile` | Bearer | doctor |
| GET | `/api/doctors/appointments/<appointment_id>/start` | Bearer | doctor |
| PUT | `/api/doctors/appointments/<appointment_id>/complete` | Bearer | doctor |
| GET | `/api/doctors/earnings` | Bearer | doctor |

```bash
curl https://clinic.nalexustechnologies.com/api/doctors/dashboard \
  -H "Authorization: Bearer <doctor_token>"
```

```bash
curl https://clinic.nalexustechnologies.com/api/doctors/appointments/1/start \
  -H "Authorization: Bearer <doctor_token>"
```

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/doctors/appointments/1/complete \
  -H "Authorization: Bearer <doctor_token>" \
  -H "Content-Type: application/json" \
  -d '{"allow_no_prescription": false}'
```

```bash
curl "https://clinic.nalexustechnologies.com/api/doctors/earnings?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <doctor_token>"
```

---

### Prescriptions

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/api/prescriptions` | Bearer | doctor |
| GET | `/api/prescriptions` | Bearer | clinic_admin, receptionist, pharmacy, doctor, super_admin |
| GET | `/api/prescriptions/<id>` | Bearer | clinic_admin, receptionist, pharmacy, doctor, assistant, patient, super_admin |
| GET | `/api/prescriptions/patient/<patient_id>` | Bearer | clinic_admin, receptionist, pharmacy, doctor, assistant, patient, super_admin |
| GET | `/api/prescriptions/appointment/<appointment_id>` | Bearer | clinic_admin, receptionist, pharmacy, doctor, assistant, patient, super_admin |
| PUT | `/api/prescriptions/<id>` | Bearer | doctor |
| DELETE | `/api/prescriptions/<id>` | Bearer | doctor |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/prescriptions \
  -H "Authorization: Bearer <doctor_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": 1,
    "patient_id": 1,
    "diagnosis": "Viral fever",
    "notes": "Hydration and rest",
    "medicines": [
      {"medicine_name":"Paracetamol","dosage":"500mg","frequency":"TID","duration":"3 days","instructions":"After meals"}
    ],
    "lab_tests": [
      {"test_name":"CBC","instructions":"Fasting not required"}
    ],
    "mark_appointment_completed": true
  }'
```

---

### Assistants (Management)

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| POST | `/api/assistants` | Bearer | doctor, clinic_admin, super_admin |
| GET | `/api/assistants` | Bearer | doctor, clinic_admin, super_admin |
| GET | `/api/assistants/my-assistants` | Bearer | doctor |
| GET | `/api/assistants/<id>` | Bearer | doctor, clinic_admin, super_admin |
| PUT | `/api/assistants/<id>` | Bearer | doctor, clinic_admin, super_admin |
| DELETE | `/api/assistants/<id>` | Bearer | doctor, clinic_admin, super_admin |

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/assistants \
  -H "Authorization: Bearer <doctor_or_clinic_admin_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Ayesha",
    "email":"ayesha.assistant@clinic.com",
    "phone":"0300-1111222",
    "doctor_id": 1,
    "permissions": {
      "can_view_appointments": true,
      "can_add_vitals": true,
      "can_upload_reports": true,
      "can_prepare_prescription_draft": true,
      "can_print_prescription": true,
      "can_view_patient_history": true
    }
  }'
```

---

### Assistant Workflow

| Method | Endpoint | Auth | Notes |
|--------|----------|------|-------|
| GET | `/api/assistant/dashboard` | Bearer assistant | Requires `can_view_appointments` |
| GET | `/api/assistant/queue` | Bearer assistant | Requires `can_view_appointments` |
| PUT | `/api/assistant/appointments/<appointment_id>/call-next` | Bearer assistant | Requires `can_view_appointments` |
| POST | `/api/assistant/vitals` | Bearer assistant | Requires `can_add_vitals` |
| GET | `/api/assistant/vitals/<patient_id>` | Bearer assistant | Requires `can_view_patient_history` |
| POST | `/api/assistant/reports` | Bearer assistant | Requires `can_upload_reports` |
| POST | `/api/assistant/symptoms-draft` | Bearer assistant | Requires `can_prepare_prescription_draft` |
| GET | `/api/assistant/patients/<patient_id>/history` | Bearer assistant | Requires `can_view_patient_history` |
| GET | `/api/assistant/prescriptions/<prescription_id>/print-data` | Bearer assistant | Requires `can_print_prescription` |

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/assistant/appointments/1/call-next \
  -H "Authorization: Bearer <assistant_token>"
```

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/assistant/vitals \
  -H "Authorization: Bearer <assistant_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "appointment_id": 1,
    "temperature": 100.2,
    "blood_pressure": "120/80",
    "pulse": 86,
    "weight": 70.5,
    "oxygen_level": 98,
    "notes": "Mild fever"
  }'
```

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/assistant/symptoms-draft \
  -H "Authorization: Bearer <assistant_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": 1,
    "patient_id": 1,
    "symptoms_draft": "Fever, sore throat",
    "vitals_summary": "Temp 100.2, BP 120/80",
    "notes": "No known allergies"
  }'
```

```bash
curl https://clinic.nalexustechnologies.com/api/assistant/prescriptions/1/print-data \
  -H "Authorization: Bearer <assistant_token>"
```

---

### Phase 7: Pharmacy Workflow

Pharmacy endpoints require an approved clinic with `has_pharmacy=true`. Pharmacy users and clinic admins are restricted to their own clinic. Super Admin must pass `clinic_id` on pharmacy/report reads where applicable.

| Method | Endpoint | Auth | Roles |
|--------|----------|------|-------|
| GET | `/api/pharmacy/dashboard` | Bearer | pharmacy, clinic_admin, super_admin |
| POST | `/api/pharmacy/items` | Bearer | pharmacy, clinic_admin |
| GET | `/api/pharmacy/items` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/items/<id>` | Bearer | pharmacy, clinic_admin, super_admin |
| PUT | `/api/pharmacy/items/<id>` | Bearer | pharmacy, clinic_admin |
| DELETE | `/api/pharmacy/items/<id>` | Bearer | pharmacy, clinic_admin |
| GET | `/api/pharmacy/low-stock` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/expiring` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/expired` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/prescription-orders` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/prescription-orders/<prescription_id>` | Bearer | pharmacy, clinic_admin, super_admin |
| PUT | `/api/pharmacy/prescription-orders/<prescription_id>/status` | Bearer | pharmacy, clinic_admin |
| POST | `/api/pharmacy/sales` | Bearer | pharmacy, clinic_admin |
| GET | `/api/pharmacy/sales` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/pharmacy/sales/<id>` | Bearer | pharmacy, clinic_admin, receptionist, patient, super_admin |
| GET | `/api/pharmacy/sales/<id>/invoice` | Bearer | pharmacy, clinic_admin, receptionist, patient, super_admin |
| GET | `/api/pharmacy/reports` | Bearer | pharmacy, clinic_admin, super_admin |
| GET | `/api/reports/pharmacy-sales` | Bearer | pharmacy, clinic_admin, super_admin |

```bash
curl https://clinic.nalexustechnologies.com/api/pharmacy/dashboard \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/pharmacy/items \
  -H "Authorization: Bearer <pharmacy_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "medicine_name": "Paracetamol",
    "category": "Pain Relief",
    "batch_number": "B-1001",
    "expiry_date": "2026-12-31",
    "purchase_price": 3.50,
    "sale_price": 5.00,
    "quantity": 200,
    "supplier": "ABC Pharma",
    "rack_number": "R1-A",
    "low_stock_limit": 20,
    "status": "active"
  }'
```

```bash
curl "https://clinic.nalexustechnologies.com/api/pharmacy/items?page=1&per_page=20&search=para&category=Pain%20Relief&status=active" \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/pharmacy/items/1 \
  -H "Authorization: Bearer <pharmacy_token>" \
  -H "Content-Type: application/json" \
  -d '{"quantity": 180, "sale_price": 5.50, "low_stock_limit": 25}'
```

```bash
curl https://clinic.nalexustechnologies.com/api/pharmacy/low-stock \
  -H "Authorization: Bearer <pharmacy_token>"
curl https://clinic.nalexustechnologies.com/api/pharmacy/expiring \
  -H "Authorization: Bearer <pharmacy_token>"
curl https://clinic.nalexustechnologies.com/api/pharmacy/expired \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl "https://clinic.nalexustechnologies.com/api/pharmacy/prescription-orders?status=pending&page=1&per_page=20" \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl https://clinic.nalexustechnologies.com/api/pharmacy/prescription-orders/1 \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl -X PUT https://clinic.nalexustechnologies.com/api/pharmacy/prescription-orders/1/status \
  -H "Authorization: Bearer <pharmacy_token>" \
  -H "Content-Type: application/json" \
  -d '{"status": "partial_dispensed"}'
```

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/pharmacy/sales \
  -H "Authorization: Bearer <pharmacy_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 1,
    "prescription_id": 1,
    "payment_status": "paid",
    "payment_method": "cash",
    "items": [
      {"medicine_id": 1, "quantity": 10}
    ]
  }'
```

```bash
curl -X POST https://clinic.nalexustechnologies.com/api/pharmacy/sales \
  -H "Authorization: Bearer <pharmacy_token>" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_status": "paid",
    "payment_method": "card",
    "items": [
      {"medicine_id": 1, "quantity": 2}
    ]
  }'
```

```bash
curl https://clinic.nalexustechnologies.com/api/pharmacy/sales/1/invoice \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl "https://clinic.nalexustechnologies.com/api/pharmacy/sales?start_date=2026-05-01&end_date=2026-05-31&payment_status=paid" \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl "https://clinic.nalexustechnologies.com/api/pharmacy/reports?start_date=2026-05-01&end_date=2026-05-31&page=1&per_page=20" \
  -H "Authorization: Bearer <pharmacy_token>"
```

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/pharmacy-sales?start_date=2026-05-01&end_date=2026-05-31&page=1&per_page=20" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

---

### Phase 8: Reports, Analytics, and Export JSON

Common query params:

- `start_date`, `end_date` in `YYYY-MM-DD`; defaults to current month.
- `doctor_id` where relevant.
- `payment_type`: `consultation`, `pharmacy`, `lab`, `other`.
- `status` where relevant.
- `group_by`: `day`, `month`, `year`.
- `export=true` returns `{report_name, generated_at, filters, summary, rows}`.

| Method | Endpoint | Roles |
|--------|----------|-------|
| GET | `/api/reports/clinic-revenue` | super_admin, clinic_admin |
| GET | `/api/reports/doctor-revenue` | super_admin, clinic_admin, doctor |
| GET | `/api/reports/pharmacy-sales` | super_admin, clinic_admin, pharmacy |
| GET | `/api/reports/patient-visits` | super_admin, clinic_admin, doctor, receptionist |
| GET | `/api/reports/appointments` | super_admin, clinic_admin, doctor, receptionist |
| GET | `/api/reports/payments` | super_admin, clinic_admin, receptionist, pharmacy |
| GET | `/api/super-admin/stats` | super_admin |
| GET | `/api/clinic-admin/reports` | super_admin, clinic_admin |
| GET | `/api/doctors/reports` | doctor |
| GET | `/api/pharmacy/reports` | super_admin, clinic_admin, pharmacy |
| GET | `/api/receptionists/reports` | super_admin, clinic_admin, receptionist |

Clinic revenue:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/clinic-revenue?start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Doctor revenue:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/doctor-revenue?doctor_id=1&start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Doctor role own revenue:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/doctor-revenue?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <doctor_token>"
```

Pharmacy sales:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/pharmacy-sales?start_date=2026-05-01&end_date=2026-05-31&page=1&per_page=20" \
  -H "Authorization: Bearer <pharmacy_token>"
```

Patient visits:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/patient-visits?start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Appointments:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/appointments?start_date=2026-05-01&end_date=2026-05-31&status=completed" \
  -H "Authorization: Bearer <receptionist_token>"
```

Payments:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/payments?start_date=2026-05-01&end_date=2026-05-31&payment_type=consultation" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Super Admin system stats:

```bash
curl "https://clinic.nalexustechnologies.com/api/super-admin/stats?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <super_admin_token>"
```

Clinic Admin complete reports:

```bash
curl "https://clinic.nalexustechnologies.com/api/clinic-admin/reports?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Doctor reports:

```bash
curl "https://clinic.nalexustechnologies.com/api/doctors/reports?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <doctor_token>"
```

Pharmacy reports:

```bash
curl "https://clinic.nalexustechnologies.com/api/pharmacy/reports?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <pharmacy_token>"
```

Receptionist reports:

```bash
curl "https://clinic.nalexustechnologies.com/api/receptionists/reports?start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <receptionist_token>"
```

Export-ready clinic revenue:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/clinic-revenue?start_date=2026-05-01&end_date=2026-05-31&export=true" \
  -H "Authorization: Bearer <clinic_admin_token>"
```

Super Admin scoped clinic report:

```bash
curl "https://clinic.nalexustechnologies.com/api/reports/clinic-revenue?clinic_id=1&start_date=2026-05-01&end_date=2026-05-31" \
  -H "Authorization: Bearer <super_admin_token>"
```

---

## Project Structure

```
clinic_backend/
├── app/
│   ├── __init__.py            App factory — registers all blueprints
│   ├── config.py              Dev / Prod / Testing configs
│   ├── extensions.py          db, jwt, migrate singletons
│   ├── models/                SQLAlchemy models
│   ├── routes/
│   │   ├── auth_routes.py     /api/auth/*
│   │   ├── clinic_routes.py   /api/clinics/*
│   │   ├── super_admin_routes.py  /api/super-admin/*
│   │   ├── clinic_admin_routes.py  /api/clinic-admin/*
│   │   ├── department_routes.py    /api/departments/*
│   │   ├── doctor_routes.py        /api/doctors/*
│   │   ├── receptionist_routes.py  /api/receptionists/*
│   │   ├── pharmacy_routes.py      /api/pharmacy/*
│   │   ├── patient_routes.py       /api/patients/*
│   │   ├── appointment_routes.py   /api/appointments/*
│   │   ├── payment_routes.py       /api/payments/*
│   │   ├── assistant_routes.py     /api/assistants/* + /api/assistant/*
│   │   ├── prescription_routes.py  /api/prescriptions/*
│   │   ├── report_routes.py        /api/reports/*
│   │   └── health_routes.py   /api/health
│   ├── services/
│   │   ├── auth_service.py    Login / token logic
│   │   ├── clinic_service.py  Registration / approval / suspension
│   │   ├── user_service.py    User creation / password management
│   │   ├── clinic_admin_service.py Dashboard / revenue / report helpers
│   │   ├── department_service.py  Department CRUD
│   │   ├── doctor_service.py   Doctor CRUD + login creation
│   │   ├── receptionist_service.py Receptionist user CRUD
│   │   ├── pharmacy_service.py Pharmacy user CRUD
│   │   ├── token_service.py    Token/patient-code generation
│   │   ├── patient_service.py  Patient CRUD + history
│   │   ├── appointment_service.py Appointment booking + queue logic
│   │   ├── payment_service.py  Payments + revenue summary
│   │   ├── assistant_service.py Assistant CRUD + workflow helpers
│   │   ├── prescription_service.py Prescription CRUD + print payload
│   │   └── report_service.py   Cross-module report endpoints
│   └── utils/
│       ├── decorators.py      role_required, clinic_access_required, clinic_approved_required
│       ├── validators.py      Input validation helpers
│       ├── password_utils.py  Hash / verify / generate temp password
│       └── response_utils.py  success_response / error_response
├── migrations/
│   └── schema.sql             Full MySQL DDL + seed data
├── requirements.txt
├── run.py                     Entry point — 0.0.0.0:5110
├── .env.example
└── README.md
```

---

## Role Reference

| Role | Scope |
|------|-------|
| `super_admin` | Full system access, no clinic restriction |
| `clinic_admin` | Own clinic only |
| `doctor` | Own clinic, own patients |
| `assistant` | Delegated doctor permissions (granular flags) |
| `receptionist` | Own clinic — appointments & patients |
| `pharmacy` | Own clinic — inventory & sales |
| `patient` | Own records only (portal) |

---

## Phase 19 — Complete Testing Guide and Sample Data

See [PHASE_19_TESTING_GUIDE.md](PHASE_19_TESTING_GUIDE.md).
