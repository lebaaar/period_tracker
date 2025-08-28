class DateHelper {
  static String formatDate(DateTime date) {
    date = date.toLocal();
    String year = date.year.toString();
    String month = date.month.toString();
    String day = date.day.toString();

    return '$day.$month.$year';
  }
}
