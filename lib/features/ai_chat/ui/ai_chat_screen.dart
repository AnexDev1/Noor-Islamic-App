import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/providers/app_providers.dart';
import '../data/app_context_provider.dart';
import 'ai_setup_screen.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Content> _chatHistory = [];

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isGeneratingWelcome = true; // New flag to track welcome message generation
  String _loadingStatus = 'Initializing...';
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initializeChat();
  }

  void _initAnimations() {
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _typingAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeChat() async {
    setState(() {
      _loadingStatus = 'Checking API configuration...';
    });

    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key');

    if (apiKey == null || apiKey.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AiSetupScreen()),
      );
      return;
    }

    try {
      setState(() {
        _loadingStatus = 'Connecting to AI service...';
      });

      Gemini.init(apiKey: apiKey);
      setState(() => _isInitialized = true);

      // Send welcome message with app context
      await _sendWelcomeMessage();
    } catch (e) {
      _showError('Failed to initialize AI: ${e.toString()}');
    }
  }

  Future<void> _sendWelcomeMessage() async {
    try {
      setState(() {
        _loadingStatus = 'Getting ready... 🕌';
        _isGeneratingWelcome = true; // Set flag when generating welcome message
      });

      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _loadingStatus = 'Fetching your location... 📍';
      });

      await Future.delayed(const Duration(milliseconds: 800));

      setState(() {
        _loadingStatus = 'Loading prayer times... ⏰';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      setState(() {
        _loadingStatus = 'Analyzing your prayer statistics... 📊';
      });

      await Future.delayed(const Duration(milliseconds: 700));

      setState(() {
        _loadingStatus = 'Preparing personalized guidance... 🤖';
      });

      // Get app context using Riverpod provider
      final appContext = await AppContextProvider.generateAppContextFromProviders(ref);

      setState(() {
        _loadingStatus = 'Almost ready... ✨';
      });

      await Future.delayed(const Duration(milliseconds: 400));

      const welcomePrompt = '''
As-salamu Alaykum! I'm your Islamic AI assistant in the Noor app. I have access to your app data and can provide personalized Islamic guidance.

Based on your current app usage, how can I help you today? I can:
- Give prayer reminders and Islamic guidance
- Answer questions about Islam
- Suggest app features that might help you
- Provide personalized advice based on your prayer habits
- Help with Quranic verses or Hadith
- Guide you in Islamic practices

What would you like to know or discuss?
''';

      final response = await Gemini.instance.prompt(parts: [
        Part.text(appContext + '\n\nUSER PROMPT:\n' + welcomePrompt),
      ]);

      if (response?.output != null) {
        _addMessage(ChatMessage(
          text: response!.output!,
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: 'As-salamu Alaykum! I\'m your Islamic AI assistant. How can I help you with your Islamic journey today?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() {
        _isGeneratingWelcome = false; // Reset flag after welcome message is generated
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty || !_isInitialized) return;

    // Update app usage
    ref.read(userPreferencesProvider.notifier).updateLastAppUsage();

    _addMessage(ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    ));

    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      // Get updated app context
      final appContext = await AppContextProvider.generateAppContextFromProviders(ref);

      final response = await Gemini.instance.prompt(parts: [
        Part.text(appContext + '\n\nUSER QUESTION:\n' + message),
      ]);

      if (response?.output != null) {
        _addMessage(ChatMessage(
          text: response!.output!,
          isUser: false,
          timestamp: DateTime.now(),
        ));

        // Add to chat history for context
        _chatHistory.add(Content(role: 'user', parts: [Part.text(message)]));
        _chatHistory.add(Content(role: 'model', parts: [Part.text(response.output!)]));
      } else {
        throw Exception('No response received');
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: 'I apologize, but I\'m having trouble responding right now. Please try again or check your connection.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading screen until both initialization and welcome message generation are complete
    if (!_isInitialized || _isGeneratingWelcome) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Islamic AI Assistant'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
              const SizedBox(height: 20),
              Text(
                _loadingStatus,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (_isGeneratingWelcome)
                Text(
                  'Generating personalized response...',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Islamic AI Assistant',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _messages.clear();
                _chatHistory.clear();
                _isGeneratingWelcome = true;
              });
              _sendWelcomeMessage();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                setState(() {
                  _messages.clear();
                  _chatHistory.clear();
                  _isGeneratingWelcome = true;
                });
                _sendWelcomeMessage();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Text('Clear Chat'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input field
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.android, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          AnimatedBuilder(
            animation: _typingAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: _typingAnimation.value),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.android, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(18) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message.text,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.body1.copyWith(
                        color: message.isUser ? Colors.white : AppColors.textPrimary,
                      ),
                      strong: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                        color: message.isUser ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: AppTextStyles.caption.copyWith(
                      color: message.isUser ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppColors.accent,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask about Islam, prayers, or app features...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            mini: true,
            onPressed: _isLoading ? null : () => _sendMessage(_messageController.text),
            child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
