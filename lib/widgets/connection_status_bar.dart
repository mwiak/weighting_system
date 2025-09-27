import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import '../providers/weight_provider.dart';
import '../providers/sync_provider.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WeightProvider, SyncProvider>(
      builder: (context, weightProvider, syncProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Weight Scale Status
            _buildStatusIndicator(
              icon: FluentIcons.scale_volume,
              isConnected: weightProvider.isConnected,
              tooltip: weightProvider.isConnected 
                  ? 'Scale connected (${weightProvider.connectedPort})'
                  : 'Scale disconnected',
            ),
            const SizedBox(width: 12),
            
            // Network Status
            _buildStatusIndicator(
              icon: syncProvider.isOnline ? FluentIcons.cloud : FluentIcons.offline_storage,
              isConnected: syncProvider.isOnline,
              tooltip: syncProvider.getConnectionStatusText() ?? 'Unknown',
            ),
            const SizedBox(width: 12),
            
            // Sync Status
            if (syncProvider.isSyncing) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: ProgressRing(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                '${(syncProvider.syncProgress * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ] else if (syncProvider.pendingSyncCount > 0) ...[
              Icon(
                FluentIcons.sync,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '${syncProvider.pendingSyncCount}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            const SizedBox(width: 16),
            
            // Current Time
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                return Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required bool isConnected,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isConnected ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}