class WebViewConsoleErrorLimiter {
  final Set<String> _seenMessages = <String>{};

  bool shouldSendRemote(String message) {
    return _seenMessages.add(message);
  }

  void clear() {
    _seenMessages.clear();
  }
}
