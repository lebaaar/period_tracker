import 'package:flutter/material.dart';

class LogPeriodPage extends StatefulWidget {
  final bool isEditing;
  final DateTimeRange? dateTimeRange;
  const LogPeriodPage({super.key, required this.isEditing, this.dateTimeRange});

  @override
  State<LogPeriodPage> createState() => _LogPeriodPageState();
}

class _LogPeriodPageState extends State<LogPeriodPage> {
  bool get isEditing => widget.isEditing;
  DateTimeRange? get dateTimeRange => widget.dateTimeRange;

  void _onSave(BuildContext context) {
    // TODO: Save to database
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Period' : 'Add Period',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          // TODO: ask if user wants to discard changes if page is dirty
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Text('isEditing: $isEditing\ndateTimeRange: $dateTimeRange.'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 50,
        margin: const EdgeInsets.all(10),
        child: ElevatedButton(
          onPressed: () => _onSave(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Center(child: Text('Save')),
        ),
      ),
    );
  }
}
