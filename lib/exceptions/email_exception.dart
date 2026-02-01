class EmailException implements Exception {
  String errorCode;
  EmailException(this.errorCode);
}
