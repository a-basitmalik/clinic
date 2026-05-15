# Phase 19 — Complete Testing Guide and Sample Data

This guide validates the full end-to-end workflow (API + Flutter UI) using **safe sample data**.

- **Do not use real production passwords** in this document.
- The only password shown here is the **sample test password**: `Admin123`.
- For clinic accounts, the backend generates **one-time temporary passwords** at clinic registration; use them and then change passwords to your own test values.

---

## 0) Before you start

### Choose environment

Set your API base URL once:

```bash
# Production (deployed)
export API_BASE="https://clinic.nalexustechnologies.com/api"

# Local example
# export API_BASE="http://127.0.0.1:5110/api"
```

### Tools

- API testing: `curl`
- Optional: `python3` (used below only to extract tokens without `jq`)
- Database verification: MySQL client (`mysql`)

---

## 1) Sample data (as requested)

### 1.1 Sample Super Admin

Create or use this Super Admin **in your test environment**:

- Email: `admin@nalexus.com`
- Password: `Admin123`

If you need to create it locally/on server:

```bash
export FLASK_APP=run.py
flask create-super-admin
# email: admin@nalexus.com
# password: Admin123
# name: Super Admin
```

### 1.2 Sample clinic registration payload

Clinic:
- Clinic name: **City Care Clinic**
- Owner: **Abdul Basit**
- Type: **multi_doctor**
- Doctors: **2**
- Has pharmacy: **yes**
- Has receptionist: **yes**

Doctors:
- Doctor 1: Dr. Ahmed — `ahmed@citycare.com` — `03000000001`
  - Specialization: General Physician
  - Department: General Medicine
  - Qualification: MBBS
  - Experience: 5
  - License: LIC001
  - Fee: 1500
- Doctor 2: Dr. Sara — `sara@citycare.com` — `03000000002`
  - Specialization: Dermatology
  - Department: Skin Specialist
  - Qualification: MBBS FCPS
  - Experience: 7
  - License: LIC002
  - Fee: 2000

Receptionist:
- Reception User — `reception@citycare.com` — `03000000003`

Pharmacy:
- Pharmacy User — `pharmacy@citycare.com` — `03000000004`

### 1.3 Sample patient

- Name: Ali Khan
- Phone: `03000000000`
- Age: 25
- Gender: `male`
- CNIC: `3520200000000`
- Address: Lahore
- Blood group: `B+`
- Emergency: `03111111111`

### 1.4 Sample medicines (inventory)

1) Paracetamol
- Category: Tablet
- Batch: PCM001
- Expiry: 2027-12-31
- Purchase: 5
- Sale: 10
- Qty: 100
- Supplier: Local Supplier
- Rack: A1
- Low stock: 10

2) Amoxicillin
- Category: Capsule
- Batch: AMX001
- Expiry: 2027-08-31
- Purchase: 20
- Sale: 35
- Qty: 50
- Supplier: Local Supplier
- Rack: B2
- Low stock: 10

3) Cough Syrup
- Category: Syrup
- Batch: CS001
- Expiry: 2026-12-31
- Purchase: 120
- Sale: 180
- Qty: 20
- Supplier: Local Supplier
- Rack: C1
- Low stock: 5

---

## 2) Helper: login and capture token (cURL only)

### 2.1 Login

```bash
curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nalexus.com","password":"Admin123"}'
```

### 2.2 Extract token into a shell variable (no jq)

```bash
export SUPER_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nalexus.com","password":"Admin123"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")

echo "SUPER_TOKEN=${SUPER_TOKEN:0:20}..."
```

---

## 3) Phase 19 test flow (API + Flutter UI)

You can run the cURL tests even if you primarily test via Flutter.

### Step 1 — Test Health API

**API**

```bash
curl -s "$API_BASE/health"
```

**Expected**
- HTTP 200
- `success: true`
- Message like `healthy` / `ok`

---

### Step 2 — Test Super Admin login

**API**

```bash
curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@nalexus.com","password":"Admin123"}'
```

**Expected**
- HTTP 200
- `data.token` present
- `data.user.role == "super_admin"`

---

### Step 3 — Register clinic (Flutter UI)

**Flutter UI**
- Open: `https://clinic.nalexustechnologies.com`
- Go to clinic registration screen
- Enter the **City Care Clinic** data exactly as above
- Submit

**Expected**
- UI shows success: clinic is pending approval
- UI shows (or backend returns) **temporary passwords** for newly created accounts

**API equivalent (recommended for predictable testing)**

```bash
curl -s -X POST "$API_BASE/clinics/register" \
  -H "Content-Type: application/json" \
  -d '{
    "clinic_name": "City Care Clinic",
    "owner_name": "Abdul Basit",
    "email": "owner@citycare.com",
    "phone": "03001234567",
    "address": "Lahore",
    "city": "Lahore",
    "clinic_type": "multi_doctor",
    "number_of_doctors": 2,
    "has_pharmacy": true,
    "has_receptionist": true,
    "opening_time": "09:00",
    "closing_time": "17:00",
    "working_days": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
    "doctors": [
      {
        "name": "Dr. Ahmed",
        "email": "ahmed@citycare.com",
        "phone": "03000000001",
        "department": "General Medicine",
        "specialization": "General Physician",
        "qualification": "MBBS",
        "experience": 5,
        "license_number": "LIC001",
        "consultation_fee": 1500,
        "available_days": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
        "available_start_time": "09:00",
        "available_end_time": "13:00"
      },
      {
        "name": "Dr. Sara",
        "email": "sara@citycare.com",
        "phone": "03000000002",
        "department": "Skin Specialist",
        "specialization": "Dermatology",
        "qualification": "MBBS FCPS",
        "experience": 7,
        "license_number": "LIC002",
        "consultation_fee": 2000,
        "available_days": ["Monday","Tuesday","Wednesday","Thursday","Friday"],
        "available_start_time": "10:00",
        "available_end_time": "14:00"
      }
    ],
    "receptionist": {
      "name": "Reception User",
      "email": "reception@citycare.com",
      "phone": "03000000003"
    },
    "pharmacy": {
      "name": "Pharmacy User",
      "email": "pharmacy@citycare.com",
      "phone": "03000000004"
    }
  }'
```

**Expected**
- HTTP 201
- `data.clinic.status == "pending"`
- `data.created_accounts` contains temp passwords (shown once)

Save these from the response:
- `CLINIC_ID`
- temp passwords for clinic_admin, doctors, receptionist, pharmacy

---

### Step 4 — View pending clinic as Super Admin

**API**

```bash
curl -s "$API_BASE/super-admin/clinics/pending?page=1&per_page=50" \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

**Expected**
- City Care Clinic appears
- Its status is `pending`

---

### Step 5 — Approve clinic

Replace `<CLINIC_ID>`.

**API**

```bash
curl -s -X PUT "$API_BASE/clinics/<CLINIC_ID>/approve" \
  -H "Authorization: Bearer $SUPER_TOKEN"
```

**Expected**
- HTTP 200
- Clinic status becomes `approved`

---

### Step 6 — Login as Clinic Admin using generated credentials

Clinic admin email is the clinic registration email (here: `owner@citycare.com`).

**Flutter UI**
- Log in with clinic admin email + temporary password
- You should be prompted to change password (must_change_password)

**API**

```bash
curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@citycare.com","password":"<TEMP_PASSWORD_FROM_STEP_3>"}'
```

Save token:

```bash
export CLINIC_ADMIN_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"owner@citycare.com","password":"<TEMP_PASSWORD_FROM_STEP_3>"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

---

### Step 7 — Add department

Note: registration already creates departments referenced by doctors. This step ensures department CRUD works.

**API**

```bash
curl -s -X POST "$API_BASE/departments" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"General Medicine","status":"active"}'
```

**Expected**
- HTTP 201
- Returns `department.id`

---

### Step 8 — Add doctor (optional)

If you want to confirm doctor creation endpoint works beyond registration:

```bash
curl -s -X POST "$API_BASE/doctors" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Dr. Test",
    "email":"dr.test@citycare.com",
    "phone":"03000000999",
    "department_id": 1,
    "specialization":"General",
    "qualification":"MBBS",
    "experience": 1,
    "license_number":"TEST-001",
    "consultation_fee": 1000,
    "available_days":["Monday"],
    "available_start_time":"09:00",
    "available_end_time":"10:00"
  }'
```

**Expected**
- HTTP 201
- Returns a `temp_password` for that doctor

---

### Step 9 — Create receptionist user (optional)

Registration already created a receptionist, but you can verify the endpoint:

```bash
curl -s -X POST "$API_BASE/receptionists" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Reception User 2","email":"reception2@citycare.com","phone":"03000000033"}'
```

---

### Step 10 — Create pharmacy user (optional)

Registration already created a pharmacy user.

```bash
curl -s -X POST "$API_BASE/pharmacy/users" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Pharmacy User 2","email":"pharmacy2@citycare.com","phone":"03000000044"}'
```

---

### Step 11 — Login as Receptionist

Use `reception@citycare.com` and its temporary password.

```bash
export RECEPTION_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"reception@citycare.com","password":"<TEMP_PASSWORD_FROM_STEP_3>"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

**Expected**
- login succeeds (only after clinic approval)

---

### Step 12 — Create patient

```bash
curl -s -X POST "$API_BASE/patients" \
  -H "Authorization: Bearer $RECEPTION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Ali Khan",
    "age": 25,
    "gender":"male",
    "phone":"03000000000",
    "cnic":"3520200000000",
    "address":"Lahore",
    "blood_group":"B+",
    "emergency_contact":"03111111111"
  }'
```

Save `PATIENT_ID` from response.

**Expected**
- HTTP 201
- Patient created with a generated `patient_code`

---

### Step 13 — Book appointment

Use Doctor 1 (Dr. Ahmed). Get doctor ids if needed:

```bash
curl -s "$API_BASE/doctors" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

Then book appointment for today:

```bash
export TODAY=$(date +%F)

curl -s -X POST "$API_BASE/appointments" \
  -H "Authorization: Bearer $RECEPTION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": <PATIENT_ID>,
    "doctor_id": <DOCTOR_1_ID>,
    "appointment_date": "'"$TODAY"'",
    "appointment_time": "11:30",
    "consultation_type": "new",
    "fee": 1500,
    "payment_status": "paid",
    "paid_amount": 1500,
    "payment_method": "cash"
  }'
```

Save `APPOINTMENT_ID`.

---

### Step 14 — Verify token number generated

The response includes `appointment.token_number` and `appointment.token_code`.

Expected:
- `token_number` is an integer (starts at 1 per doctor+date)
- `token_code` is non-empty

---

### Step 15 — Update queue status

Receptionist can send patient to assistant or cancel.

```bash
curl -s -X PUT "$API_BASE/appointments/<APPOINTMENT_ID>/status" \
  -H "Authorization: Bearer $RECEPTION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"waiting"}'
```

Expected:
- HTTP 200

---

### Step 16 — Login as Doctor

Doctor accounts were created at registration. Login as Dr. Ahmed using its temp password.

```bash
export DOCTOR_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"ahmed@citycare.com","password":"<TEMP_PASSWORD_FROM_STEP_3>"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

---

### Step 17 — View today queue

```bash
curl -s "$API_BASE/doctors/queue" \
  -H "Authorization: Bearer $DOCTOR_TOKEN"
```

Expected:
- Appointment is present in queue

---

### Step 18 — Start consultation

```bash
curl -s "$API_BASE/doctors/appointments/<APPOINTMENT_ID>/start" \
  -H "Authorization: Bearer $DOCTOR_TOKEN"
```

Expected:
- appointment status becomes `in_consultation`

---

### Step 19 — Create prescription

```bash
curl -s -X POST "$API_BASE/prescriptions" \
  -H "Authorization: Bearer $DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "appointment_id": <APPOINTMENT_ID>,
    "patient_id": <PATIENT_ID>,
    "symptoms": "Fever and sore throat",
    "diagnosis": "Viral infection",
    "notes": "Rest and fluids",
    "medicines": [
      {"medicine_name":"Paracetamol","dosage":"500mg","frequency":"2x/day","duration":"3 days"},
      {"medicine_name":"Amoxicillin","dosage":"500mg","frequency":"3x/day","duration":"5 days"}
    ],
    "lab_tests": [
      {"test_name":"CBC","instructions":"Fasting not required"}
    ],
    "mark_appointment_completed": false
  }'
```

Save `PRESCRIPTION_ID`.

Expected:
- HTTP 201
- `prescription.pharmacy_status == "pending"`

---

### Step 20 — Add medicines (already in Step 19)

Expected:
- medicines array contains Paracetamol + Amoxicillin

---

### Step 21 — Add lab tests (already in Step 19)

Expected:
- lab_tests array contains CBC

---

### Step 22 — Complete appointment

Doctor can complete.

```bash
curl -s -X PUT "$API_BASE/doctors/appointments/<APPOINTMENT_ID>/complete" \
  -H "Authorization: Bearer $DOCTOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"notes":"Consultation completed"}'
```

Expected:
- appointment status becomes `completed`

---

### Step 23 — Login as Pharmacy

```bash
export PHARMACY_TOKEN=$(curl -s -X POST "$API_BASE/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"pharmacy@citycare.com","password":"<TEMP_PASSWORD_FROM_STEP_3>"}' \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])")
```

---

### Step 24 — Add medicines to inventory

Create the 3 inventory items.

```bash
curl -s -X POST "$API_BASE/pharmacy/items" \
  -H "Authorization: Bearer $PHARMACY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "medicine_name":"Paracetamol",
    "category":"Tablet",
    "batch_number":"PCM001",
    "expiry_date":"2027-12-31",
    "purchase_price":5,
    "sale_price":10,
    "quantity":100,
    "supplier":"Local Supplier",
    "rack_number":"A1",
    "low_stock_limit":10,
    "status":"active"
  }'

curl -s -X POST "$API_BASE/pharmacy/items" \
  -H "Authorization: Bearer $PHARMACY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "medicine_name":"Amoxicillin",
    "category":"Capsule",
    "batch_number":"AMX001",
    "expiry_date":"2027-08-31",
    "purchase_price":20,
    "sale_price":35,
    "quantity":50,
    "supplier":"Local Supplier",
    "rack_number":"B2",
    "low_stock_limit":10,
    "status":"active"
  }'

curl -s -X POST "$API_BASE/pharmacy/items" \
  -H "Authorization: Bearer $PHARMACY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "medicine_name":"Cough Syrup",
    "category":"Syrup",
    "batch_number":"CS001",
    "expiry_date":"2026-12-31",
    "purchase_price":120,
    "sale_price":180,
    "quantity":20,
    "supplier":"Local Supplier",
    "rack_number":"C1",
    "low_stock_limit":5,
    "status":"active"
  }'
```

Expected:
- Each returns HTTP 201
- Save each `medicine.id` for the sale step

---

### Step 25 — View prescription order

```bash
curl -s "$API_BASE/pharmacy/prescription-orders?status=pending&page=1&per_page=20" \
  -H "Authorization: Bearer $PHARMACY_TOKEN"
```

Expected:
- Prescription appears
- `order_status == "pending"`

---

### Step 26 — Create pharmacy sale from prescription

You must supply `items[].medicine_id` from inventory.

Example: sell 2 Paracetamol + 1 Amoxicillin.

```bash
curl -s -X POST "$API_BASE/pharmacy/sales" \
  -H "Authorization: Bearer $PHARMACY_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "prescription_id": <PRESCRIPTION_ID>,
    "patient_id": <PATIENT_ID>,
    "payment_status": "paid",
    "payment_method": "cash",
    "items": [
      {"medicine_id": <PARACETAMOL_ID>, "quantity": 2},
      {"medicine_id": <AMOXICILLIN_ID>, "quantity": 1}
    ]
  }'
```

Save `SALE_ID`.

Expected:
- HTTP 201
- Sale contains items and totals
- Prescription `pharmacy_status` becomes `dispensed` or `partial_dispensed`

---

### Step 27 — Verify stock deduction

```bash
curl -s "$API_BASE/pharmacy/items/<PARACETAMOL_ID>" \
  -H "Authorization: Bearer $PHARMACY_TOKEN"
```

Expected:
- Paracetamol quantity reduced (100 → 98)

---

### Step 28 — View invoice

```bash
curl -s "$API_BASE/pharmacy/sales/<SALE_ID>/invoice" \
  -H "Authorization: Bearer $PHARMACY_TOKEN"
```

Expected:
- `invoice.sale` and `invoice.items` present
- totals match item quantities x sale_price

---

### Step 29 — Login as Patient (if patient login exists)

This backend supports `patient` role reads if:
- there is a `users` row with `role="patient"`, and
- `patients.user_id` links to that user.

If your Flutter app includes patient login/registration, follow that flow.

Expected:
- Patient can only access their own profile/prescriptions/invoices

---

### Step 30 — Patient views prescription and bill

**API (patient role)**
- `GET /api/prescriptions/<id>` should succeed only if prescription belongs to that patient
- `GET /api/pharmacy/sales/<id>/invoice` should succeed only if sale belongs to that patient

---

### Step 31 — Login as Clinic Admin

Reuse `$CLINIC_ADMIN_TOKEN`.

---

### Step 32 — View revenue report

**Quick clinic summary**

```bash
curl -s "$API_BASE/clinic-admin/revenue" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

**Full report engine**

```bash
curl -s "$API_BASE/reports/clinic-revenue?start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

Expected:
- `summary.total_revenue` increases after consultation + pharmacy sale

---

### Step 33 — View doctor revenue report

```bash
curl -s "$API_BASE/reports/doctor-revenue?doctor_id=<DOCTOR_1_ID>&start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

Expected:
- Doctor’s consultation revenue reflects the paid appointment

---

### Step 34 — View pharmacy sales report

Two options:

**A) Global reports blueprint**

```bash
curl -s "$API_BASE/reports/pharmacy-sales?start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

**B) Pharmacy blueprint**

```bash
curl -s "$API_BASE/pharmacy/reports?start_date=2026-05-01&end_date=2026-05-31&group_by=day" \
  -H "Authorization: Bearer $PHARMACY_TOKEN"
```

Expected:
- `summary.total_sales` > 0
- `rows` / `sales_detail` include the sale you created

---

### Step 35 — Test logout

```bash
curl -s -X POST "$API_BASE/auth/logout" \
  -H "Authorization: Bearer $CLINIC_ADMIN_TOKEN"
```

Expected:
- HTTP 200
- Note: JWT is stateless; client discards token

---

### Step 36 — Test role protection

Example: receptionist should not create a doctor.

```bash
curl -s -X POST "$API_BASE/doctors" \
  -H "Authorization: Bearer $RECEPTION_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"Dr. Hacker","email":"hack@citycare.com","department_id":1}'
```

Expected:
- HTTP 403 (access denied)

---

### Step 37 — Test invalid/expired token handling

**Invalid token**

```bash
curl -s "$API_BASE/auth/me" \
  -H "Authorization: Bearer not-a-real-token"
```

Expected:
- HTTP 401
- Message mentions invalid token

**Expired token**

To test expiration reliably, temporarily set a low JWT lifetime in your environment and re-login (then wait until it expires). After expiry:
- call `/api/auth/me`
- expect HTTP 401 and message: `Token has expired. Please log in again.`

---

## 4) Database verification SQL queries

Run these on the **test database**.

### 4.1 Find the clinic id

```sql
SELECT id, clinic_name, status, has_pharmacy, has_receptionist
FROM clinics
WHERE clinic_name = 'City Care Clinic';
```

### 4.2 Verify users created

```sql
SELECT id, name, email, role, clinic_id, status, must_change_password
FROM users
WHERE clinic_id = <CLINIC_ID>
ORDER BY role, id;
```

### 4.3 Verify doctors + departments

```sql
SELECT d.id, d.name, d.email, d.specialization, dep.name AS department
FROM doctors d
LEFT JOIN departments dep ON dep.id = d.department_id
WHERE d.clinic_id = <CLINIC_ID>;
```

### 4.4 Verify patient

```sql
SELECT id, patient_code, name, phone, cnic, clinic_id
FROM patients
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC
LIMIT 5;
```

### 4.5 Verify appointment + token

```sql
SELECT id, clinic_id, doctor_id, patient_id, appointment_date, token_number, status, fee, payment_status
FROM appointments
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC
LIMIT 10;
```

### 4.6 Verify prescription order visibility

```sql
SELECT id, clinic_id, appointment_id, patient_id, doctor_id, pharmacy_status, created_at
FROM prescriptions
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC
LIMIT 10;
```

### 4.7 Verify pharmacy inventory + deduction

```sql
SELECT id, medicine_name, batch_number, quantity, low_stock_limit, expiry_date, status
FROM pharmacy_items
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC;
```

### 4.8 Verify sale + items

```sql
SELECT id, clinic_id, patient_id, prescription_id, total_amount, payment_status, payment_method, created_at
FROM pharmacy_sales
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC
LIMIT 10;

SELECT s.id AS sale_id, i.medicine_id, pi.medicine_name, i.quantity, i.unit_price, i.total_price
FROM pharmacy_sale_items i
JOIN pharmacy_sales s ON s.id = i.sale_id
JOIN pharmacy_items pi ON pi.id = i.medicine_id
WHERE s.clinic_id = <CLINIC_ID>
ORDER BY i.id DESC
LIMIT 50;
```

### 4.9 Verify payments ledger

```sql
SELECT id, clinic_id, patient_id, appointment_id, payment_type, amount, method, status, created_at
FROM payments
WHERE clinic_id = <CLINIC_ID>
ORDER BY id DESC
LIMIT 50;
```

---

## 5) Safe test data reset

If you ran tests on a shared environment, **do not delete production data**.

### Option A (recommended): use a separate test database

- Create a dedicated database like `clinic_test`
- Run schema
- Point backend `.env` to it

### Option B: delete only the City Care Clinic data (SQL)

Run in a transaction and verify `<CLINIC_ID>` first.

```sql
START TRANSACTION;

-- Verify scope
SELECT id, clinic_name FROM clinics WHERE id = <CLINIC_ID> FOR UPDATE;

-- Delete children first (order matters)
DELETE FROM pharmacy_sale_items WHERE sale_id IN (SELECT id FROM pharmacy_sales WHERE clinic_id = <CLINIC_ID>);
DELETE FROM pharmacy_sales WHERE clinic_id = <CLINIC_ID>;
DELETE FROM pharmacy_items WHERE clinic_id = <CLINIC_ID>;

DELETE FROM prescription_lab_tests WHERE prescription_id IN (SELECT id FROM prescriptions WHERE clinic_id = <CLINIC_ID>);
DELETE FROM prescription_medicines WHERE prescription_id IN (SELECT id FROM prescriptions WHERE clinic_id = <CLINIC_ID>);
DELETE FROM prescriptions WHERE clinic_id = <CLINIC_ID>;

DELETE FROM payments WHERE clinic_id = <CLINIC_ID>;
DELETE FROM appointments WHERE clinic_id = <CLINIC_ID>;
DELETE FROM patients WHERE clinic_id = <CLINIC_ID>;
DELETE FROM assistants WHERE clinic_id = <CLINIC_ID>;
DELETE FROM doctors WHERE clinic_id = <CLINIC_ID>;
DELETE FROM departments WHERE clinic_id = <CLINIC_ID>;
DELETE FROM users WHERE clinic_id = <CLINIC_ID>;

DELETE FROM clinics WHERE id = <CLINIC_ID>;

COMMIT;
```

If anything looks wrong, run `ROLLBACK;` instead of `COMMIT;`.

---

## 6) Common errors and fixes

### 401 Authentication required

Symptoms:
- `success=false` and message like `Authentication required. No token provided.`

Fix:
- Add `-H "Authorization: Bearer <token>"`

### 401 Token expired

Fix:
- Login again
- Ensure device time is correct

### 403 Access denied

Fix:
- Use a token with the correct role
- Validate clinic context (`clinic_id`) exists in token

### 409 Duplicate email

Fix:
- Registration requires unique emails across clinic admin + doctors + receptionist + pharmacy

### 422 Validation failed

Fix:
- Check required fields and formats
  - Dates: `YYYY-MM-DD`
  - Times: `HH:MM`

### Pharmacy disabled (422)

If clinic was registered with `has_pharmacy=false`, pharmacy endpoints return:
- `This clinic does not have pharmacy enabled.`

Fix:
- Register clinic with `has_pharmacy=true`

---

## 7) Backend logs and debugging

### Production (systemd + gunicorn)

```bash
sudo systemctl status clinic-backend
sudo journalctl -u clinic-backend -f
sudo nginx -t
sudo systemctl reload nginx
```

### Local

```bash
python run.py
```

---

## 8) Flutter Web browser console errors

In Chrome:
- Open DevTools → Console
- Look for:
  - CORS errors
  - 401/403 API failures
  - Mixed content errors (HTTP calls on HTTPS page)

Expected for production:
- Frontend calls `https://clinic.nalexustechnologies.com/api/...` over HTTPS
- No CORS or mixed-content errors
