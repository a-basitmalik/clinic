-- =============================================================================
-- Clinic Management System — Full MySQL Schema
-- Database : clinic
-- Charset  : utf8mb4 (full Unicode, emoji-safe)
-- Engine   : InnoDB (FK enforcement, transactions)
--
-- Run order is intentional: deferred FKs (circular deps) are added at the end
-- via ALTER TABLE so every table can be created in a clean linear pass.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS `clinic`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE `clinic`;

SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- 1. subscription_plans  (no deps on other custom tables)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `subscription_plans` (
    `id`            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    `name`          VARCHAR(100)    NOT NULL,
    `price`         DECIMAL(10,2)   NOT NULL DEFAULT 0.00,
    `duration_days` INT             NOT NULL DEFAULT 30,
    `max_doctors`   INT             NOT NULL DEFAULT 1,
    `has_pharmacy`  TINYINT(1)      NOT NULL DEFAULT 0,
    `has_reports`   TINYINT(1)      NOT NULL DEFAULT 1,
    `status`        ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_plan_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 2. clinics  (FK to subscription_plans; circular FK to users added later)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `clinics` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_name`          VARCHAR(200) NOT NULL,
    `owner_name`           VARCHAR(200) NOT NULL,
    `email`                VARCHAR(120) NOT NULL,
    `phone`                VARCHAR(20)  NOT NULL,
    `address`              TEXT,
    `city`                 VARCHAR(100),
    `logo`                 VARCHAR(500),
    `clinic_type`          ENUM('single_doctor','multi_doctor') NOT NULL,
    `number_of_doctors`    INT          NOT NULL DEFAULT 1,
    `has_pharmacy`         TINYINT(1)   NOT NULL DEFAULT 0,
    `has_receptionist`     TINYINT(1)   NOT NULL DEFAULT 0,
    `opening_time`         TIME,
    `closing_time`         TIME,
    `working_days`         JSON,
    `status`               ENUM('pending','approved','suspended') NOT NULL DEFAULT 'pending',
    `subscription_plan_id` INT UNSIGNED,
    `approved_by`          INT UNSIGNED,   -- FK added later (circular dep with users)
    `approved_at`          DATETIME,
    `created_at`           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_clinic_email` (`email`),
    KEY `idx_clinic_status` (`status`),
    CONSTRAINT `fk_clinics_plan`
        FOREIGN KEY (`subscription_plan_id`)
        REFERENCES `subscription_plans` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 3. users  (FK to clinics; circular FK to doctors added later)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id`                   INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `name`                 VARCHAR(200) NOT NULL,
    `email`                VARCHAR(120) NOT NULL,
    `phone`                VARCHAR(20),
    `password_hash`        VARCHAR(255) NOT NULL,
    `role`                 ENUM('super_admin','clinic_admin','doctor','assistant',
                                'receptionist','pharmacy','patient') NOT NULL,
    `clinic_id`            INT UNSIGNED,
    `doctor_id`            INT UNSIGNED,  -- FK added later (circular dep with doctors)
    `status`               ENUM('active','inactive','pending') NOT NULL DEFAULT 'active',
    `must_change_password` TINYINT(1)   NOT NULL DEFAULT 0,
    `last_login`           DATETIME,
    `created_at`           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_user_email` (`email`),
    KEY `idx_user_clinic`  (`clinic_id`),
    KEY `idx_user_role`    (`role`),
    KEY `idx_user_status`  (`status`),
    CONSTRAINT `fk_users_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 4. departments  (FK to clinics)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `departments` (
    `id`          INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`   INT UNSIGNED NOT NULL,
    `name`        VARCHAR(150) NOT NULL,
    `description` TEXT,
    `status`      ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_dept_clinic` (`clinic_id`),
    CONSTRAINT `fk_departments_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 5. doctors  (FK to clinics, users, departments)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `doctors` (
    `id`                   INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`            INT UNSIGNED  NOT NULL,
    `user_id`              INT UNSIGNED  UNIQUE,
    `department_id`        INT UNSIGNED,
    `name`                 VARCHAR(200)  NOT NULL,
    `email`                VARCHAR(120)  NOT NULL,
    `phone`                VARCHAR(20),
    `specialization`       VARCHAR(200),
    `qualification`        VARCHAR(300),
    `experience`           INT,
    `license_number`       VARCHAR(100),
    `consultation_fee`     DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `available_days`       JSON,
    `available_start_time` TIME,
    `available_end_time`   TIME,
    `status`               ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`           DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_doctor_clinic`  (`clinic_id`),
    KEY `idx_doctor_status`  (`status`),
    CONSTRAINT `fk_doctors_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_doctors_user`
        FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_doctors_department`
        FOREIGN KEY (`department_id`)
        REFERENCES `departments` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 6. Resolve circular FKs now that both users and doctors tables exist
-- ---------------------------------------------------------------------------
ALTER TABLE `users`
    ADD CONSTRAINT `fk_users_doctor_id`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE SET NULL;

ALTER TABLE `clinics`
    ADD CONSTRAINT `fk_clinics_approved_by`
        FOREIGN KEY (`approved_by`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL;

-- ---------------------------------------------------------------------------
-- 7. assistants
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `assistants` (
    `id`                           INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`                    INT UNSIGNED NOT NULL,
    `doctor_id`                    INT UNSIGNED NOT NULL,
    `user_id`                      INT UNSIGNED UNIQUE,
    `name`                         VARCHAR(200) NOT NULL,
    `duties`                       JSON,
    `can_view_appointments`        TINYINT(1)   NOT NULL DEFAULT 1,
    `can_add_vitals`               TINYINT(1)   NOT NULL DEFAULT 1,
    `can_upload_reports`           TINYINT(1)   NOT NULL DEFAULT 0,
    `can_prepare_prescription_draft` TINYINT(1) NOT NULL DEFAULT 0,
    `can_print_prescription`       TINYINT(1)   NOT NULL DEFAULT 0,
    `can_view_patient_history`     TINYINT(1)   NOT NULL DEFAULT 1,
    `status`                       ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`                   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`                   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_assistant_clinic`  (`clinic_id`),
    KEY `idx_assistant_doctor`  (`doctor_id`),
    CONSTRAINT `fk_assistants_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_assistants_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_assistants_user`
        FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 8. patients
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patients` (
    `id`                INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`         INT UNSIGNED NOT NULL,
    `user_id`           INT UNSIGNED UNIQUE,
    `patient_code`      VARCHAR(50)  NOT NULL,
    `name`              VARCHAR(200) NOT NULL,
    `age`               INT,
    `gender`            ENUM('male','female','other'),
    `phone`             VARCHAR(20)  NOT NULL,
    `cnic`              VARCHAR(20),
    `address`           TEXT,
    `blood_group`       VARCHAR(10),
    `emergency_contact` VARCHAR(20),
    `created_by`        INT UNSIGNED,
    `created_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_patient_code_per_clinic` (`clinic_id`, `patient_code`),
    KEY `idx_patient_phone`  (`phone`),
    KEY `idx_patient_clinic` (`clinic_id`),
    CONSTRAINT `fk_patients_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_patients_user`
        FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_patients_created_by`
        FOREIGN KEY (`created_by`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 9. appointments
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `appointments` (
    `id`                INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`         INT UNSIGNED  NOT NULL,
    `doctor_id`         INT UNSIGNED  NOT NULL,
    `patient_id`        INT UNSIGNED  NOT NULL,
    `receptionist_id`   INT UNSIGNED,
    `appointment_date`  DATE          NOT NULL,
    `appointment_time`  TIME          NOT NULL,
    `token_number`      INT           NOT NULL,
    `consultation_type` ENUM('new','followup','emergency') NOT NULL DEFAULT 'new',
    `status`            ENUM('waiting','sent_to_assistant','in_consultation',
                             'completed','cancelled') NOT NULL DEFAULT 'waiting',
    `fee`               DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `payment_status`    ENUM('unpaid','paid','partial') NOT NULL DEFAULT 'unpaid',
    `notes`             TEXT,
    `created_at`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_token_per_doctor_per_day`
        (`clinic_id`, `doctor_id`, `appointment_date`, `token_number`),
    KEY `idx_appt_date`    (`appointment_date`),
    KEY `idx_appt_status`  (`status`),
    KEY `idx_appt_patient` (`patient_id`),
    KEY `idx_appt_doctor`  (`doctor_id`),
    CONSTRAINT `fk_appt_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_appt_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_appt_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_appt_receptionist`
        FOREIGN KEY (`receptionist_id`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 10. prescriptions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prescriptions` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`      INT UNSIGNED NOT NULL,
    `doctor_id`      INT UNSIGNED,
    `patient_id`     INT UNSIGNED NOT NULL,
    `appointment_id` INT UNSIGNED UNIQUE,
    `symptoms`       TEXT,
    `diagnosis`      TEXT,
    `notes`          TEXT,
    `follow_up_date` DATE,
    `pharmacy_status` ENUM('pending','partial_dispensed','dispensed','cancelled') NOT NULL DEFAULT 'pending',
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_rx_patient` (`patient_id`),
    KEY `idx_rx_doctor`  (`doctor_id`),
    KEY `idx_rx_clinic`  (`clinic_id`),
    KEY `idx_rx_pharmacy_status` (`pharmacy_status`),
    CONSTRAINT `fk_rx_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_rx_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_rx_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_rx_appointment`
        FOREIGN KEY (`appointment_id`)
        REFERENCES `appointments` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 11. pharmacy_items  (must exist before prescription_medicines)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pharmacy_items` (
    `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`       INT UNSIGNED  NOT NULL,
    `medicine_name`   VARCHAR(200)  NOT NULL,
    `category`        VARCHAR(100),
    `batch_number`    VARCHAR(100),
    `expiry_date`     DATE,
    `purchase_price`  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `sale_price`      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `quantity`        INT           NOT NULL DEFAULT 0,
    `supplier`        VARCHAR(200),
    `rack_number`     VARCHAR(50),
    `low_stock_limit` INT           NOT NULL DEFAULT 10,
    `status`          ENUM('active','inactive') NOT NULL DEFAULT 'active',
    `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_pharma_clinic`  (`clinic_id`),
    KEY `idx_pharma_status`  (`status`),
    KEY `idx_pharma_expiry`  (`expiry_date`),
    CONSTRAINT `fk_pharma_items_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 12. prescription_medicines  (depends on prescriptions + pharmacy_items)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prescription_medicines` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `prescription_id` INT UNSIGNED NOT NULL,
    `medicine_id`     INT UNSIGNED,
    `medicine_name`   VARCHAR(200) NOT NULL,
    `dosage`          VARCHAR(100),
    `frequency`       VARCHAR(100),
    `duration`        VARCHAR(100),
    `instructions`    TEXT,
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_rxmed_prescription` (`prescription_id`),
    CONSTRAINT `fk_rxmed_prescription`
        FOREIGN KEY (`prescription_id`)
        REFERENCES `prescriptions` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_rxmed_pharma_item`
        FOREIGN KEY (`medicine_id`)
        REFERENCES `pharmacy_items` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 13. pharmacy_sales
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pharmacy_sales` (
    `id`              INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`       INT UNSIGNED  NOT NULL,
    `patient_id`      INT UNSIGNED,
    `prescription_id` INT UNSIGNED,
    `total_amount`    DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `payment_status`  ENUM('paid','pending','partial') NOT NULL DEFAULT 'pending',
    `payment_method`  ENUM('cash','card','easypaisa','jazzcash','bank') NOT NULL DEFAULT 'cash',
    `sold_by`         INT UNSIGNED,
    `created_at`      DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sale_clinic`   (`clinic_id`),
    KEY `idx_sale_patient`  (`patient_id`),
    CONSTRAINT `fk_sales_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_sales_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_sales_prescription`
        FOREIGN KEY (`prescription_id`)
        REFERENCES `prescriptions` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_sales_sold_by`
        FOREIGN KEY (`sold_by`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 14. pharmacy_sale_items
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pharmacy_sale_items` (
    `id`          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `sale_id`     INT UNSIGNED  NOT NULL,
    `medicine_id` INT UNSIGNED  NOT NULL,
    `quantity`    INT           NOT NULL,
    `unit_price`  DECIMAL(10,2) NOT NULL,
    `total_price` DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (`id`),
    KEY `idx_sale_item_sale` (`sale_id`),
    CONSTRAINT `fk_sale_items_sale`
        FOREIGN KEY (`sale_id`)
        REFERENCES `pharmacy_sales` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_sale_items_medicine`
        FOREIGN KEY (`medicine_id`)
        REFERENCES `pharmacy_items` (`id`)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 15. payments
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `payments` (
    `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`      INT UNSIGNED  NOT NULL,
    `patient_id`     INT UNSIGNED,
    `appointment_id` INT UNSIGNED,
    `payment_type`   ENUM('consultation','pharmacy','lab','other') NOT NULL,
    `amount`         DECIMAL(10,2) NOT NULL,
    `method`         ENUM('cash','card','easypaisa','jazzcash','bank') NOT NULL DEFAULT 'cash',
    `status`         ENUM('paid','pending','refunded') NOT NULL DEFAULT 'paid',
    `received_by`    INT UNSIGNED,
    `created_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_payment_clinic`  (`clinic_id`),
    KEY `idx_payment_patient` (`patient_id`),
    KEY `idx_payment_date`    (`created_at`),
    CONSTRAINT `fk_payments_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_payments_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_payments_appointment`
        FOREIGN KEY (`appointment_id`)
        REFERENCES `appointments` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_payments_received_by`
        FOREIGN KEY (`received_by`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 16. audit_logs
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `audit_logs` (
    `id`         INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`  INT UNSIGNED,
    `user_id`    INT UNSIGNED,
    `action`     VARCHAR(100) NOT NULL,
    `module`     VARCHAR(100),
    `details`    JSON,
    `ip_address` VARCHAR(50),
    `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_audit_clinic`  (`clinic_id`),
    KEY `idx_audit_user`    (`user_id`),
    KEY `idx_audit_created` (`created_at`),
    CONSTRAINT `fk_audit_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_audit_user`
        FOREIGN KEY (`user_id`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 17. clinic_subscriptions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `clinic_subscriptions` (
    `id`           INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`    INT UNSIGNED  NOT NULL,
    `plan_id`      INT UNSIGNED  NOT NULL,
    `start_date`   DATE          NOT NULL,
    `end_date`     DATE          NOT NULL,
    `status`       ENUM('active','expired','cancelled') NOT NULL DEFAULT 'active',
    `amount_paid`  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    `created_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`   DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_sub_clinic`  (`clinic_id`),
    KEY `idx_sub_status`  (`status`),
    CONSTRAINT `fk_sub_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_sub_plan`
        FOREIGN KEY (`plan_id`)
        REFERENCES `subscription_plans` (`id`)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 18. patient_vitals
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient_vitals` (
    `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`      INT UNSIGNED  NOT NULL,
    `patient_id`     INT UNSIGNED  NOT NULL,
    `appointment_id` INT UNSIGNED,
    `doctor_id`      INT UNSIGNED  NOT NULL,
    `assistant_id`   INT UNSIGNED,
    `temperature`    DECIMAL(5,2),
    `blood_pressure` VARCHAR(20),
    `pulse`          INT,
    `weight`         DECIMAL(6,2),
    `height`         DECIMAL(6,2),
    `oxygen_level`   INT,
    `notes`          TEXT,
    `created_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_vitals_clinic` (`clinic_id`),
    KEY `idx_vitals_patient` (`patient_id`),
    KEY `idx_vitals_appt` (`appointment_id`),
    KEY `idx_vitals_doctor` (`doctor_id`),
    CONSTRAINT `fk_vitals_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_vitals_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_vitals_appointment`
        FOREIGN KEY (`appointment_id`)
        REFERENCES `appointments` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_vitals_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_vitals_assistant`
        FOREIGN KEY (`assistant_id`)
        REFERENCES `assistants` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 19. patient_reports
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `patient_reports` (
    `id`             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    `clinic_id`      INT UNSIGNED  NOT NULL,
    `patient_id`     INT UNSIGNED  NOT NULL,
    `appointment_id` INT UNSIGNED,
    `doctor_id`      INT UNSIGNED  NOT NULL,
    `uploaded_by`    INT UNSIGNED,
    `report_title`   VARCHAR(200)  NOT NULL,
    `report_type`    VARCHAR(100),
    `file_url`       VARCHAR(500),
    `notes`          TEXT,
    `created_at`     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_reports_clinic` (`clinic_id`),
    KEY `idx_reports_patient` (`patient_id`),
    KEY `idx_reports_appt` (`appointment_id`),
    KEY `idx_reports_doctor` (`doctor_id`),
    CONSTRAINT `fk_reports_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_reports_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_reports_appointment`
        FOREIGN KEY (`appointment_id`)
        REFERENCES `appointments` (`id`)
        ON DELETE SET NULL,
    CONSTRAINT `fk_reports_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_reports_uploaded_by`
        FOREIGN KEY (`uploaded_by`)
        REFERENCES `users` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 20. prescription_lab_tests
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `prescription_lab_tests` (
    `id`              INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `prescription_id` INT UNSIGNED NOT NULL,
    `test_name`       VARCHAR(200) NOT NULL,
    `instructions`    TEXT,
    `created_at`      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_labtest_prescription` (`prescription_id`),
    CONSTRAINT `fk_labtest_prescription`
        FOREIGN KEY (`prescription_id`)
        REFERENCES `prescriptions` (`id`)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------------------------
-- 21. consultation_drafts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `consultation_drafts` (
    `id`             INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `clinic_id`      INT UNSIGNED NOT NULL,
    `appointment_id` INT UNSIGNED NOT NULL,
    `patient_id`     INT UNSIGNED NOT NULL,
    `doctor_id`      INT UNSIGNED NOT NULL,
    `assistant_id`   INT UNSIGNED,
    `symptoms_draft` TEXT,
    `vitals_summary` TEXT,
    `notes`          TEXT,
    `created_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at`     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uq_draft_appointment` (`appointment_id`),
    KEY `idx_draft_clinic` (`clinic_id`),
    KEY `idx_draft_patient` (`patient_id`),
    KEY `idx_draft_doctor` (`doctor_id`),
    CONSTRAINT `fk_draft_clinic`
        FOREIGN KEY (`clinic_id`)
        REFERENCES `clinics` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_draft_appointment`
        FOREIGN KEY (`appointment_id`)
        REFERENCES `appointments` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_draft_patient`
        FOREIGN KEY (`patient_id`)
        REFERENCES `patients` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_draft_doctor`
        FOREIGN KEY (`doctor_id`)
        REFERENCES `doctors` (`id`)
        ON DELETE CASCADE,
    CONSTRAINT `fk_draft_assistant`
        FOREIGN KEY (`assistant_id`)
        REFERENCES `assistants` (`id`)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- SEED DATA
-- =============================================================================

-- Default subscription plans
INSERT INTO `subscription_plans`
    (`name`, `price`, `duration_days`, `max_doctors`, `has_pharmacy`, `has_reports`, `status`)
VALUES
    ('Basic',    0.00,   30,  1,  0, 1, 'active'),
    ('Standard', 2999.00, 30, 5,  1, 1, 'active'),
    ('Premium',  5999.00, 30, 20, 1, 1, 'active')
ON DUPLICATE KEY UPDATE `price` = VALUES(`price`);

-- =============================================================================
-- Super Admin
-- Do NOT insert a hardcoded super admin here.
-- Run this after schema import:
--
--   export FLASK_APP=run.py
--   flask create-super-admin
--
-- =============================================================================
