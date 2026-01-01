/// PawaPay Mobile Money Integration Configuration
/// 
/// Supports MTN, Airtel, and Zamtel in Zambia (ZMW currency)
/// 
/// Setup:
/// 1. Create sandbox account at https://dashboard.sandbox.pawapay.io/#/merchant-signup
/// 2. Generate API token from dashboard
/// 3. Replace the placeholder token below
/// 4. For production, update to production URLs and token
library;

class PawapayConfig {
  // Environment flag - set to false for production
  static const bool isSandbox = true;

  // API Base URLs
  static const String sandboxBaseUrl = 'https://api.sandbox.pawapay.io';
  static const String productionBaseUrl = 'https://api.pawapay.io';

  // Dashboard URLs (for reference)
  static const String sandboxDashboard = 'https://dashboard.sandbox.pawapay.io';
  static const String productionDashboard = 'https://dashboard.pawapay.io';

  // API Token - Replace with your actual token from PawaPay Dashboard
  // IMPORTANT: In production, use secure storage (environment variables, secure vault)
  static const String sandboxApiToken = 'eyJraWQiOiIxIiwiYWxnIjoiRVMyNTYifQ.eyJ0dCI6IkFBVCIsInN1YiI6IjE0NzQ0IiwibWF2IjoiMSIsImV4cCI6MjA4MjgyMDg3OSwiaWF0IjoxNzY3Mjg4MDc5LCJwbSI6IkRBRixQQUYiLCJqdGkiOiIwOTIyOTQwNC00Y2E5LTRkMDUtYWQ2NS0yYWIxNjI5Njc3ZmIifQ.lXFV6N0Kx3-r8eWyQipZv-LyuvVOQyvJU-l6Q_Bpe08tiqNlbhou52PY_nXlg3NlFfSqjNKpkd5kLF_ldj-v1w';
  static const String productionApiToken = 'YOUR_PRODUCTION_API_TOKEN_HERE';

  // Get current base URL based on environment
  static String get baseUrl => isSandbox ? sandboxBaseUrl : productionBaseUrl;

  // Get current API token based on environment
  static String get apiToken => isSandbox ? sandboxApiToken : productionApiToken;

  // API Endpoints
  static String get depositsEndpoint => '$baseUrl/v2/deposits';
  static String get payoutsEndpoint => '$baseUrl/v2/payouts';
  static String get activeConfigEndpoint => '$baseUrl/v2/active-conf';
  static String get predictProviderEndpoint => '$baseUrl/v2/predict-provider';
  static String get availabilityEndpoint => '$baseUrl/v2/availability';

  // Get deposit status endpoint
  static String depositStatusEndpoint(String depositId) =>
      '$baseUrl/v2/deposits/$depositId';

  // Get payout status endpoint
  static String payoutStatusEndpoint(String payoutId) =>
      '$baseUrl/v2/payouts/$payoutId';

  // Zambia-specific configuration
  static const String countryCode = 'ZMB';
  static const String currency = 'ZMW';
  static const String phonePrefix = '260';

  // Zambian Mobile Money Operators (MMOs)
  static const List<MmoProvider> zambianProviders = [
    MmoProvider(
      code: 'MTN_MOMO_ZMB',
      name: 'MTN Mobile Money',
      shortName: 'MTN MoMo',
      logoAsset: 'assets/images/mtn_logo.png',
      minAmount: 1.0,
      maxAmount: 50000.0,
    ),
    MmoProvider(
      code: 'AIRTEL_ZMB',
      name: 'Airtel Money',
      shortName: 'Airtel Money',
      logoAsset: 'assets/images/airtel_logo.png',
      minAmount: 1.0,
      maxAmount: 50000.0,
    ),
    MmoProvider(
      code: 'ZAMTEL_ZMB',
      name: 'Zamtel Kwacha',
      shortName: 'Zamtel',
      logoAsset: 'assets/images/zamtel_logo.png',
      minAmount: 1.0,
      maxAmount: 50000.0,
    ),
  ];

  // Test phone numbers for sandbox (from PawaPay docs)
  static const Map<String, List<String>> testPhoneNumbers = {
    'MTN_MOMO_ZMB': [
      '260760000001', // Success
      '260760000002', // Insufficient funds
      '260760000003', // General failure
    ],
    'AIRTEL_ZMB': [
      '260970000001', // Success
      '260970000002', // Insufficient funds
      '260970000003', // General failure
    ],
    'ZAMTEL_ZMB': [
      '260950000001', // Success
      '260950000002', // Insufficient funds
      '260950000003', // General failure
    ],
  };

  // Phone number prefixes for provider detection
  static const Map<String, List<String>> providerPrefixes = {
    'MTN_MOMO_ZMB': ['26076', '26096'],
    'AIRTEL_ZMB': ['26097', '26077'],
    'ZAMTEL_ZMB': ['26095', '26055'],
  };

  // Detect provider from phone number
  static String? detectProviderFromPhone(String phoneNumber) {
    final normalizedPhone = normalizePhoneNumber(phoneNumber);
    for (final entry in providerPrefixes.entries) {
      for (final prefix in entry.value) {
        if (normalizedPhone.startsWith(prefix)) {
          return entry.key;
        }
      }
    }
    return null;
  }

  // Normalize phone number to format: 260XXXXXXXXX
  static String normalizePhoneNumber(String phone) {
    // Remove all non-digit characters
    String digits = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Handle various formats
    if (digits.startsWith('00260')) {
      digits = digits.substring(2); // Remove 00
    } else if (digits.startsWith('+260')) {
      digits = digits.substring(1); // Remove +
    } else if (digits.startsWith('0') && digits.length == 10) {
      digits = '260${digits.substring(1)}'; // Convert 0XX to 260XX
    } else if (!digits.startsWith('260') && digits.length == 9) {
      digits = '260$digits'; // Add country code
    }

    return digits;
  }

  // Validate phone number format
  static bool isValidZambianPhone(String phone) {
    final normalized = normalizePhoneNumber(phone);
    // Zambian numbers: 260 + 9 digits = 12 digits total
    if (normalized.length != 12) return false;
    if (!normalized.startsWith('260')) return false;
    // Check if it matches any known provider prefix
    return detectProviderFromPhone(normalized) != null;
  }

  // HTTP Headers for API calls
  static Map<String, String> get headers => {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Polling configuration for payment status
  static const int maxPollAttempts = 30;
  static const Duration pollInterval = Duration(seconds: 3);
  static const Duration requestTimeout = Duration(seconds: 30);
}

/// Mobile Money Operator Provider model
class MmoProvider {
  final String code;
  final String name;
  final String shortName;
  final String logoAsset;
  final double minAmount;
  final double maxAmount;

  const MmoProvider({
    required this.code,
    required this.name,
    required this.shortName,
    required this.logoAsset,
    required this.minAmount,
    required this.maxAmount,
  });

  @override
  String toString() => name;
}
