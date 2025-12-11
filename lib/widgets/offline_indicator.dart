import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/offline_provider.dart';

class OfflineIndicator extends StatelessWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineProvider>(
      builder: (context, offlineProvider, _) {
        if (offlineProvider.isOnline && !offlineProvider.hasPendingOperations) {
          return SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: offlineProvider.isOffline
                ? Colors.red.shade600
                : Colors.orange.shade600,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              if (offlineProvider.isSyncing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(
                  offlineProvider.isOffline
                      ? Icons.cloud_off
                      : Icons.cloud_upload,
                  color: Colors.white,
                  size: 16,
                ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(offlineProvider),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (offlineProvider.hasPendingOperations && offlineProvider.isOnline)
                TextButton(
                  onPressed: () {
                    offlineProvider.syncPendingOperations();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                  child: Text('Sync Now'),
                ),
            ],
          ),
        );
      },
    );
  }

  String _getStatusText(OfflineProvider provider) {
    if (provider.isSyncing) {
      return 'Syncing ${provider.pendingOperationsCount} operations...';
    } else if (provider.isOffline) {
      if (provider.hasPendingOperations) {
        return 'Offline • ${provider.pendingOperationsCount} operations pending';
      }
      return 'Offline mode • Data will sync when connection is restored';
    } else if (provider.hasPendingOperations) {
      return '${provider.pendingOperationsCount} operations pending sync';
    }
    return '';
  }
}
