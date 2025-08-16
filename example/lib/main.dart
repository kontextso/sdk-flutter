import 'dart:math';
import 'package:flutter/material.dart';
import 'package:kontext_flutter_sdk/kontext_flutter_sdk.dart';
import 'constants.dart';

void main() {
  runApp(const DemoApp());
}

class DemoApp extends StatefulWidget {
  const DemoApp({super.key});
  @override
  State<DemoApp> createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    final isDark = _themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'Kontext Flutter Demo',
      themeMode: _themeMode,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: HomePage(
        isDark: isDark,
        onToggleTheme: () {
          setState(() {
            _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
          });
        },
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.isDark, required this.onToggleTheme});
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _id() => '${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  late final String conversationId = _id();
  late final String userId = _id();

  final List<Message> _messages = [];
  final TextEditingController _input = TextEditingController();
  bool _isLoading = false;

  void _append(Message m) => setState(() => _messages.add(m));

  void _onSubmit() {
    final text = _input.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Add the user message
    _append(Message(
      id: _id(),
      role: MessageRole.user,
      content: text,
      createdAt: DateTime.now(),
    ));

    _input.clear();
    FocusScope.of(context).unfocus();

    // Simulate assistant reply after delay
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _append(Message(
        id: _id(),
        role: MessageRole.assistant,
        content: 'This is a test response from the assistant.',
        createdAt: DateTime.now(),
      ));
      setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.isDark ? 'dark' : 'light';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontext Demo'),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
          ),
        ],
      ),
      body: AdsProvider(
        publisherToken: kPublisherToken,
        userId: userId,
        conversationId: conversationId,
        messages: _messages,
        enabledPlacementCodes: const [kPlacementCode],
        logLevel: LogLevel.info,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show "loading..." row if assistant is typing
                  if (_isLoading && index == _messages.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Loading...'),
                    );
                  }

                  final msg = _messages[index];
                  return Padding(
                    key: ValueKey(msg.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${msg.role.name}:',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(msg.content),
                        const SizedBox(height: 8),

                        // Inline ad slot under each message
                        InlineAd(
                          code: kPlacementCode,
                          messageId: msg.id,
                          otherParams: {'theme': theme},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 2,
                      maxLines: 6,
                      decoration: InputDecoration(
                        hintText: 'Type your message here…',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      enabled: !_isLoading,
                      onSubmitted: (_) => _onSubmit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
