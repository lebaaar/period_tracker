import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';
import 'package:period_tracker/services/application_data_service.dart';
import 'package:flutter/services.dart';

/// A two-tab help page for restore & transfer flows.
///
/// Pass [initialTab] as either 'restore' (default) or 'transfer' to open the
/// corresponding tab.
class RestoreHelpPage extends StatelessWidget {
  final String initialTab;

  const RestoreHelpPage({super.key, this.initialTab = 'restore'});

  @override
  Widget build(BuildContext context) {
    final int initialIndex = (initialTab == 'transfer') ? 1 : 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Help', style: Theme.of(context).textTheme.titleMedium),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: Theme.of(context).colorScheme.onSurface,
            onPressed: () {
              context.pop();
            },
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Restore Data'),
              Tab(text: 'Transfer Data'),
            ],
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.onSurface,
            unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [_buildRestoreTab(context), _buildTransferTab(context)],
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.restore_rounded,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'To restore data you need the $kBackupFileName file on your device. Locate the file and open it with this app.'
              'This data is generated on the old device using the "Backup Data" option in your profile.'
              'After ',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 24),
          // ElevatedButton(
          //   onPressed: () {
          //     // open file picker is handled elsewhere; this keeps the page informational
          //   },
          //   child: const Text('Open file manager'),
          // ),
        ],
      ),
    );
  }

  Widget _buildTransferTab(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To transfer your data to another device, create a backup using "Backup Data" in your profile and send the backup file to yourself (for example via email).',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'On the new device, download the backup file, then open it with this app to restore your data.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Note: install and open Period Tracker at least once before restoring the backup file on the new device.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final content = await ApplicationDataService()
                          .createBackupFileContent();
                      final xfile = await ApplicationDataService()
                          .exportBackupToFile(content);
                      if (!context.mounted) return;
                      await Clipboard.setData(ClipboardData(text: xfile.path));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Backup created — path copied to clipboard:\n${xfile.path}',
                          ),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create backup: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Send backup'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
