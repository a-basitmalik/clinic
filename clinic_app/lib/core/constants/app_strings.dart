class AppStrings {
  AppStrings._();

  static const String appName    = 'Clinic Management System';
  static const String appTagline = 'Healthcare made simple';

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String login          = 'Sign In';
  static const String logout         = 'Sign Out';
  static const String email          = 'Email Address';
  static const String password       = 'Password';
  static const String currentPassword = 'Current Password';
  static const String newPassword    = 'New Password';
  static const String changePassword = 'Change Password';
  static const String welcomeBack    = 'Welcome back!';
  static const String signInToContinue = 'Sign in to access your dashboard';
  static const String registerClinic = 'Register New Clinic';

  // ── Navigation ────────────────────────────────────────────────────────────
  static const String dashboard       = 'Dashboard';
  static const String clinics         = 'Clinics';
  static const String pendingApprovals = 'Pending Approvals';
  static const String departments     = 'Departments';
  static const String doctors         = 'Doctors';
  static const String receptionists   = 'Receptionists';
  static const String pharmacyUsers   = 'Pharmacy Users';
  static const String patients        = 'Patients';
  static const String appointments    = 'Appointments';
  static const String prescriptions   = 'Prescriptions';
  static const String payments        = 'Payments';
  static const String revenue         = 'Revenue';
  static const String reports         = 'Reports';
  static const String inventory       = 'Inventory';
  static const String sales           = 'Sales';
  static const String queue           = 'My Queue';
  static const String assistants      = 'Assistants';
  static const String earnings        = 'Earnings';
  static const String myProfile       = 'My Profile';
  static const String settings        = 'Settings';

  // ── Common ────────────────────────────────────────────────────────────────
  static const String save    = 'Save';
  static const String cancel  = 'Cancel';
  static const String delete  = 'Delete';
  static const String edit    = 'Edit';
  static const String create  = 'Create';
  static const String search  = 'Search…';
  static const String loading = 'Loading…';
  static const String retry   = 'Retry';
  static const String noData  = 'No data available';
  static const String comingSoon = 'Coming Soon';
  static const String comingSoonDesc =
      'This section is under development and will be available in a future update.';

  // ── Roles (display names) ─────────────────────────────────────────────────
  static String roleLabel(String role) {
    switch (role) {
      case 'super_admin':  return 'Super Admin';
      case 'clinic_admin': return 'Clinic Admin';
      case 'doctor':       return 'Doctor';
      case 'assistant':    return 'Doctor Assistant';
      case 'receptionist': return 'Receptionist';
      case 'pharmacy':     return 'Pharmacy';
      case 'patient':      return 'Patient';
      default:             return role;
    }
  }
}
