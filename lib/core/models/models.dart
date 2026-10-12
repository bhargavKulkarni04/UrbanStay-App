/// ==============================================================================
/// URBANSTAY CORE ENTERPRISE MODELS BARREL EXPORT
/// Purpose: Single centralized export for all 23 strongly-typed production data models
/// Reference: MASTER_DATABASE_SCHEMA.md & supabase/migrations/
/// ==============================================================================

// Pillar 1: Auth, Profiles & Leads
export 'profile_model.dart';
export 'lead_model.dart';

// Pillar 2: Property & Live Bed Inventory
export 'property_model.dart';
export 'room_model.dart';
export 'bed_model.dart';

// Pillar 3: Tenant Lifecycle & Onboarding
export 'tenant_model.dart';
export 'onboarding_request_model.dart';
export 'move_out_notice_model.dart';

// Pillar 4: 0% Direct UPI Ledger & Approvals
export 'rent_ledger_model.dart';
export 'payment_approval_model.dart';
export 'rent_extension_model.dart';
export 'warden_cash_model.dart';
export 'damage_deduction_model.dart';

// Pillar 5: Operations, Helpdesk & Food Mess
export 'maintenance_ticket_model.dart';
export 'food_menu_model.dart';
export 'housekeeping_model.dart';
export 'announcement_model.dart';

// Pillar 6: Staff & Property Team
export 'staff_model.dart';
export 'property_team_model.dart';
export 'expense_model.dart';

// Pillar 7: Settings & B2B SaaS Licensing
export 'property_settings_model.dart';
export 'saas_subscription_model.dart';
export 'saas_invoice_model.dart';
