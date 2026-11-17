enum FeedbackType {
  feedback('Feedback', 'Feedback', 0x5865F2),
  featureRequest('Feature request', 'Feature request', 0x57F287),
  bugReport('Bug report', 'Bug report', 0xED4245);

  final String label;
  final String title;
  final int color;
  const FeedbackType(this.label, this.title, this.color);

  /// Feature requests and bug reports include device info and app data.
  bool get includesAppData => this != FeedbackType.feedback;
}
