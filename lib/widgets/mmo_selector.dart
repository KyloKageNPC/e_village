import 'package:flutter/material.dart';
import '../config/pawapay_config.dart';

/// Mobile Money Operator Selector Widget
/// 
/// Displays Zambian MMO providers (MTN, Airtel, Zamtel) for selection
class MmoSelector extends StatelessWidget {
  final String? selectedProvider;
  final ValueChanged<String?> onProviderSelected;
  final bool enabled;

  const MmoSelector({
    super.key,
    this.selectedProvider,
    required this.onProviderSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Mobile Money Provider',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: PawapayConfig.zambianProviders.map((provider) {
            final isSelected = selectedProvider == provider.code;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _ProviderCard(
                  provider: provider,
                  isSelected: isSelected,
                  enabled: enabled,
                  onTap: () => onProviderSelected(provider.code),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final MmoProvider provider;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  const _ProviderCard({
    required this.provider,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getProviderColor(provider.code);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Provider icon/logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  _getProviderInitials(provider.code),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.shortName,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.check_circle,
                color: color,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getProviderColor(String code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return const Color(0xFFFFCC00); // MTN Yellow
      case 'AIRTEL_ZMB':
        return const Color(0xFFED1C24); // Airtel Red
      case 'ZAMTEL_ZMB':
        return const Color(0xFF00A651); // Zamtel Green
      default:
        return Colors.blue;
    }
  }

  String _getProviderInitials(String code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return 'MTN';
      case 'AIRTEL_ZMB':
        return 'AIR';
      case 'ZAMTEL_ZMB':
        return 'ZAM';
      default:
        return '?';
    }
  }
}

/// Phone Number Input with Provider Detection
/// 
/// Auto-detects and suggests provider based on phone number prefix
class MobileMoneyPhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String? selectedProvider;
  final ValueChanged<String?> onProviderDetected;
  final String? errorText;
  final bool enabled;

  const MobileMoneyPhoneInput({
    super.key,
    required this.controller,
    this.selectedProvider,
    required this.onProviderDetected,
    this.errorText,
    this.enabled = true,
  });

  @override
  State<MobileMoneyPhoneInput> createState() => _MobileMoneyPhoneInputState();
}

class _MobileMoneyPhoneInputState extends State<MobileMoneyPhoneInput> {
  String? _detectedProvider;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = widget.controller.text;
    if (phone.length >= 6) {
      final detected = PawapayConfig.detectProviderFromPhone(phone);
      if (detected != _detectedProvider) {
        setState(() {
          _detectedProvider = detected;
        });
        widget.onProviderDetected(detected);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPhoneChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Money Phone Number',
            hintText: '097XXXXXXX or 076XXXXXXX',
            prefixIcon: const Icon(Icons.phone_android),
            prefixText: '+260 ',
            suffixIcon: _detectedProvider != null
                ? _ProviderBadge(providerCode: _detectedProvider!)
                : null,
            errorText: widget.errorText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            if (!PawapayConfig.isValidZambianPhone(value)) {
              return 'Invalid Zambian phone number';
            }
            return null;
          },
        ),
        if (_detectedProvider != null) ...[
          const SizedBox(height: 8),
          Text(
            'Detected: ${_getProviderName(_detectedProvider!)}',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  String _getProviderName(String code) {
    for (final provider in PawapayConfig.zambianProviders) {
      if (provider.code == code) {
        return provider.name;
      }
    }
    return code;
  }
}

class _ProviderBadge extends StatelessWidget {
  final String providerCode;

  const _ProviderBadge({required this.providerCode});

  @override
  Widget build(BuildContext context) {
    final color = _getProviderColor(providerCode);
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _getProviderShortName(providerCode),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProviderColor(String code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return const Color(0xFFFFCC00);
      case 'AIRTEL_ZMB':
        return const Color(0xFFED1C24);
      case 'ZAMTEL_ZMB':
        return const Color(0xFF00A651);
      default:
        return Colors.blue;
    }
  }

  String _getProviderShortName(String code) {
    switch (code) {
      case 'MTN_MOMO_ZMB':
        return 'MTN';
      case 'AIRTEL_ZMB':
        return 'Airtel';
      case 'ZAMTEL_ZMB':
        return 'Zamtel';
      default:
        return '?';
    }
  }
}

/// Payment Status Indicator Widget
/// 
/// Shows the current state of a mobile money transaction
class PaymentStatusIndicator extends StatelessWidget {
  final String status;
  final String? message;
  final bool isProcessing;

  const PaymentStatusIndicator({
    super.key,
    required this.status,
    this.message,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = _getStatusDetails(status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isProcessing)
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            )
          else
            Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  (IconData, Color, String) _getStatusDetails(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return (Icons.hourglass_empty, Colors.orange, 'Payment Pending');
      case 'processing':
        return (Icons.sync, Colors.blue, 'Processing Payment');
      case 'awaitingconfirmation':
        return (Icons.phone_android, Colors.blue, 'Check your phone');
      case 'completed':
        return (Icons.check_circle, Colors.green, 'Payment Successful!');
      case 'failed':
        return (Icons.error, Colors.red, 'Payment Failed');
      default:
        return (Icons.info, Colors.grey, status);
    }
  }
}

/// Mobile Money Payment Summary Card
class PaymentSummaryCard extends StatelessWidget {
  final double amount;
  final String provider;
  final String phoneNumber;
  final String? description;

  const PaymentSummaryCard({
    super.key,
    required this.amount,
    required this.provider,
    required this.phoneNumber,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Summary',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(),
            _buildRow(context, 'Amount', 'K ${amount.toStringAsFixed(2)}'),
            _buildRow(context, 'Provider', _getProviderName(provider)),
            _buildRow(context, 'Phone', _formatPhone(phoneNumber)),
            if (description != null)
              _buildRow(context, 'Description', description!),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getProviderName(String code) {
    for (final p in PawapayConfig.zambianProviders) {
      if (p.code == code) return p.name;
    }
    return code;
  }

  String _formatPhone(String phone) {
    final normalized = PawapayConfig.normalizePhoneNumber(phone);
    if (normalized.length == 12) {
      return '+${normalized.substring(0, 3)} ${normalized.substring(3, 6)} ${normalized.substring(6)}';
    }
    return phone;
  }
}
