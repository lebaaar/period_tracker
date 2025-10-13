import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:period_tracker/constants.dart';

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restore_rounded,
            size: 75,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To restore data you need the $kBackupFileName file on your (new) device. Below are the detailed instructions on how to restore your data.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Prerequisites:\n'
                  '- Installed Period Tracker app on your new device.\n'
                  '- $kBackupFileName file on your new device. If you do not have this file, see instructions in the "Transfer Data" tab on how to obtain it.\n',
                ),
                const SizedBox(height: 12),
                Text('1. Open the Files app on your new device.'),
                const SizedBox(height: 12),
                Text(
                  '2. Locate the $kBackupFileName file. By default it will be in the "Downloads" folder.',
                ),
                const SizedBox(height: 12),
                Text(
                  '3. Long press the $kBackupFileName file, click on the 3 dots and select "Open with".',
                ),
                const SizedBox(height: 12),
                Text('4. Select Period Tracker from the list of apps.'),
                const SizedBox(height: 12),
                Text('5. Period Tracker app opens.'),
                Text(
                  'Important: if you restore data from $kBackupFileName on a device that already has an account, all existing data will be replaced with the data from the backup file.',
                ),
                const SizedBox(height: 12),
                Text(
                  '6. Confirm that you want to restore data from the backup file by clicking "Restore my data".',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTransferTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.cloud_upload_rounded,
            size: 75,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'To transfer your data to another device, you need to carry over a backup file from your old device to the new one. Below are the detailed instructions on how to transfer the backup file.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  '1. On your old device, navigate to "Profile" and select "Transfer Data" under "Account & Data".',
                ),
                const SizedBox(height: 12),
                Text(
                  '2. Click "Send backup file" in the dialog that appears. Sharing options will open, with the $kBackupFileName file attached.',
                ),
                const SizedBox(height: 12),
                Text(
                  '3. Select how you want to share the $kBackupFileName file (e.g. via email). You will need to be able to access this file on your new device.',
                ),
                const SizedBox(height: 12),
                Text(
                  '4. If you selected email, your email app will open with the $kBackupFileName file attached. Send the email to yourself.',
                ),
                const SizedBox(height: 12),
                Text(
                  '5. On your new device, open the email you sent to yourself and download the $kBackupFileName file.',
                ),
                const SizedBox(height: 12),
                Text(
                  'For instructions on how to restore data from the $kBackupFileName file on your new device, see the "Restore Data" tab.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
