import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/group_service.dart';

class JoinGroupByCodeScreen extends StatefulWidget {
  const JoinGroupByCodeScreen({super.key});

  @override
  State<JoinGroupByCodeScreen> createState() => _JoinGroupByCodeScreenState();
}

class _JoinGroupByCodeScreenState extends State<JoinGroupByCodeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  final GroupService _groupService = GroupService();
  
  bool _isLoading = false;
  bool _isScanning = true;
  Map<String, dynamic>? _groupPreview;
  String? _errorMessage;
  String? _scannedCode;

  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == 1) {
      // QR Scanner tab - initialize controller
      _scannerController ??= MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
      setState(() => _isScanning = true);
    } else {
      // Code entry tab - pause scanning
      _scannerController?.stop();
      setState(() => _isScanning = false);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _codeController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _lookupCode(String code) async {
    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an invite code';
        _groupPreview = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _groupPreview = null;
      _scannedCode = code.toUpperCase();
    });

    try {
      final preview = await _groupService.getGroupPreviewByCode(code);
      
      if (preview != null) {
        setState(() {
          _groupPreview = preview;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid invite code. Please check and try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error looking up code: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_scannedCode == null) return;

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join a group'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _groupService.joinGroupByInviteCode(
        inviteCode: _scannedCode!,
        userId: userId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined ${_groupPreview!['name']}!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null) {
        // Parse the QR code data
        String? code;
        
        // Check if it's our custom URL format
        if (rawValue.startsWith('evillage://join?code=')) {
          code = rawValue.replaceFirst('evillage://join?code=', '');
        } else if (rawValue.length == 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(rawValue.toUpperCase())) {
          // Direct code format
          code = rawValue.toUpperCase();
        }

        if (code != null && code.isNotEmpty) {
          setState(() => _isScanning = false);
          _scannerController?.stop();
          _lookupCode(code);
          break;
        }
      }
    }
  }

  void _resetScan() {
    setState(() {
      _isScanning = true;
      _groupPreview = null;
      _errorMessage = null;
      _scannedCode = null;
    });
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Group'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.keyboard), text: 'Enter Code'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan QR'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCodeEntryTab(),
          _buildQRScannerTab(),
        ],
      ),
    );
  }

  Widget _buildCodeEntryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_add,
              size: 40,
              color: Colors.teal,
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Enter Invite Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Enter the 6-character code shared with you',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Code input
          TextField(
            controller: _codeController,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              hintText: 'ABC123',
              hintStyle: TextStyle(
                color: Colors.grey[300],
                letterSpacing: 8,
              ),
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
            ),
            onChanged: (value) {
              if (value.length == 6) {
                _lookupCode(value);
              }
            },
          ),

          const SizedBox(height: 16),

          // Lookup button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _lookupCode(_codeController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Find Group',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Group preview
          if (_groupPreview != null) ...[
            const SizedBox(height: 24),
            _buildGroupPreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildQRScannerTab() {
    if (_groupPreview != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildGroupPreview(),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _resetScan,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan Another Code'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: _scannerController,
                onDetect: _onBarcodeDetected,
              ),
              // Overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.teal, width: 3),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              // Clear the scan area
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 250,
                    height: 250,
                    color: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            children: [
              const Text(
                'Point your camera at the QR code',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The group invite code will be detected automatically',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _resetScan,
                  child: const Text('Try Again'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroupPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Success icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 36,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'Group Found!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 20),

          // Group info
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.groups,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            _groupPreview!['name'] ?? 'Unknown Group',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          if (_groupPreview!['description'] != null) ...[
            const SizedBox(height: 8),
            Text(
              _groupPreview!['description'],
              style: TextStyle(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],

          if (_groupPreview!['location'] != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  _groupPreview!['location'],
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                '${_groupPreview!['member_count']} members',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Join button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Join This Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
