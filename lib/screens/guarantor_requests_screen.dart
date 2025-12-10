import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/guarantor_provider.dart';
import '../providers/auth_provider.dart';
import '../models/loan_guarantor_model.dart';

class GuarantorRequestsScreen extends StatefulWidget {
  const GuarantorRequestsScreen({super.key});

  @override
  State<GuarantorRequestsScreen> createState() =>
      _GuarantorRequestsScreenState();
}

class _GuarantorRequestsScreenState extends State<GuarantorRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  Future<void> _loadRequests() async {
    final authProvider = context.read<AuthProvider>();
    final guarantorProvider = context.read<GuarantorProvider>();

    if (authProvider.currentUser != null) {
      await guarantorProvider.loadGuarantorRequests(
        userId: authProvider.currentUser!.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade100,
      appBar: AppBar(
        title: Text(
          'Guarantor Requests',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange.shade600,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Consumer<GuarantorProvider>(
        builder: (context, guarantorProvider, _) {
          if (guarantorProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.orange.shade600,
              ),
            );
          }

          if (guarantorProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade400),
                  SizedBox(height: 16),
                  Text(
                    'Error loading requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      guarantorProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: Colors.black.withValues(alpha: 0.6)),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRequests,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (guarantorProvider.guarantorRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 80,
                    color: Colors.orange.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No Guarantor Requests',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You have no pending guarantor requests',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRequests,
            color: Colors.orange.shade600,
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: guarantorProvider.guarantorRequests.length,
              itemBuilder: (context, index) {
                final request = guarantorProvider.guarantorRequests[index];
                return _buildRequestCard(request);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(LoanGuarantorModel request) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM dd, yyyy');

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case GuarantorStatus.pending:
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.pending;
        statusText = 'Pending Response';
        break;
      case GuarantorStatus.approved:
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle;
        statusText = 'Approved';
        break;
      case GuarantorStatus.rejected:
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel;
        statusText = 'Rejected';
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.orange.shade500],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, color: Colors.white, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Guarantor Request',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Guaranteed Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      currencyFormat.format(request.guaranteedAmount),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Date
                _buildInfoRow(
                  'Requested Date',
                  dateFormat.format(request.requestedAt),
                ),
                if (request.respondedAt != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    'Responded Date',
                    dateFormat.format(request.respondedAt!),
                  ),
                ],
                if (request.responseMessage != null) ...[
                  SizedBox(height: 12),
                  _buildInfoRow(
                    'Your Response',
                    request.responseMessage!,
                  ),
                ],
                SizedBox(height: 20),

                // Action Buttons (only for pending requests)
                if (request.isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectRequest(request.id),
                          icon: Icon(Icons.close, size: 18),
                          label: Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(color: Colors.red.shade600),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveRequest(request.id),
                          icon: Icon(Icons.check, size: 18),
                          label: Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _approveRequest(String guarantorId) async {
    final guarantorProvider = context.read<GuarantorProvider>();

    final success = await guarantorProvider.approveRequest(
      guarantorId: guarantorId,
      message: 'I agree to guarantee this loan',
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guarantor request approved!'),
          backgroundColor: Colors.green.shade600,
        ),
      );
      await _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve request'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> _rejectRequest(String guarantorId) async {
    final guarantorProvider = context.read<GuarantorProvider>();

    final success = await guarantorProvider.rejectRequest(
      guarantorId: guarantorId,
      message: 'Unable to guarantee at this time',
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guarantor request rejected'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
      await _loadRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject request'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }
}
