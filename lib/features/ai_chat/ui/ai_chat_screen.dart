import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common_widgets/custom_app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/constants.dart';
import '../data/app_context_provider.dart';
import '../logic/prayer_tracking_service.dart';
import 'ai_setup_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<Content> _chatHistory = [];

  bool _isLoading = false;
  bool _isInitialized = false;
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key');

      if (apiKey == null || apiKey.isEmpty || apiKey == 'placeholder') {
        // No valid API key, redirect to setup
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const AiSetupScreen()),
          );
        }
        return;
      }

      // Initialize Gemini with the actual API key (only once we have a valid key)
      Gemini.init(apiKey: apiKey);

      // Test the API key by making a simple request
      await _testApiKey();

      // Update app usage for personalization
      await AppContextProvider.updateAppUsage();

      setState(() {
        _isInitialized = true;
        _messages.add(ChatMessage(
          text: 'السلام عليكم ورحمة الله وبركاته!\n\nWelcome to **Noor** - your personalized Islamic AI Assistant! 🕌\n\nI now have access to your:\n• 📊 Prayer statistics and spiritual journey\n• 🗺️ Location and prayer times\n• ⚙️ App preferences and usage patterns\n• 📱 All Noor app features\n\nThis allows me to provide **highly personalized Islamic guidance** tailored specifically to you!\n\n### Ask me about:\n• Quranic verses and their meanings\n• Hadith and Islamic teachings\n• **Personalized prayer guidance** based on your habits\n• Islamic history and scholars\n• Fiqh (Islamic jurisprudence)\n• Du\'as and supplications\n• **App feature recommendations**\n\nHow may I assist you on your spiritual journey today? 🤲',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    } catch (e) {
      print('Chat initialization error: $e');
      _showError('Failed to initialize AI assistant. Please check your API key.');
      // Redirect to setup screen if initialization fails
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AiSetupScreen()),
        );
      }
    }
  }

  Future<void> _testApiKey() async {
    try {
      final gemini = Gemini.instance;
      // Make a simple test request to verify the API key works
      await gemini.prompt(parts: [Part.text('Hello')]);
    } catch (e) {
      print('API key test failed: $e');
      // Clear the invalid API key
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gemini_api_key');
      throw Exception('Invalid API key');
    }
  }

  @override
  void dispose() {
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Immediately show the user message and set loading state
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Generate Islamic context asynchronously (this was causing the delay)
      final contextualizedMessage = await _addIslamicContext(text);

      // Add user message to chat history
      _chatHistory.add(Content(parts: [Part.text(contextualizedMessage)], role: 'user'));

      final gemini = Gemini.instance;

      // Use chat method for conversation continuity
      final response = await gemini.chat(_chatHistory);

      if (response?.output != null) {
        final aiResponse = response!.output!;

        // Add AI response to chat history
        _chatHistory.add(Content(parts: [Part.text(aiResponse)], role: 'model'));

        setState(() {
          _messages.add(ChatMessage(
            text: aiResponse,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      } else {
        throw Exception('No response received');
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'I apologize, but I\'m having trouble responding right now. Please check your internet connection and API key, then try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _showError('Failed to get AI response: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _addIslamicContext(String userMessage) async {
    // Determine if this needs full context or just conversational context
    final needsFullContext = _shouldIncludeFullContext(userMessage);

    if (needsFullContext) {
      // Get comprehensive app context for complex questions
      final appContext = await AppContextProvider.generateAppContext();
      return _buildFullContext(userMessage, appContext);
    } else {
      // Use minimal context for casual conversation
      return _buildConversationalContext(userMessage);
    }
  }

  bool _shouldIncludeFullContext(String message) {
    final lowercaseMessage = message.toLowerCase();

    // Include full context for specific Islamic topics or app-related questions
    final fullContextTriggers = [
      'prayer', 'salah', 'namaz', 'quran', 'hadith', 'fiqh', 'islamic', 'sunnah',
      'madhab', 'scholar', 'ruling', 'haram', 'halal', 'dua', 'dhikr', 'tasbih',
      'qibla', 'azkhar', 'app', 'feature', 'how to use', 'help me', 'guidance',
      'what is', 'explain', 'tell me about', 'teach me', 'verses', 'ayah', 'surah'
    ];

    // Check if message contains specific Islamic topics
    for (String trigger in fullContextTriggers) {
      if (lowercaseMessage.contains(trigger)) {
        return true;
      }
    }

    // Include full context for longer, detailed questions
    if (message.length > 50) {
      return true;
    }

    return false;
  }

  String _buildFullContext(String userMessage, String appContext) {
    return '''You are an Islamic assistant in the NOOR Islamic app. Your role is to provide authentic, trusted Islamic knowledge to users. You must base every answer strictly on:

1. The Qur'an (with surah & ayah number if possible)
2. The authentic Hadith collections (Sahih al-Bukhari, Sahih Muslim, Sunan Abu Dawood, etc.)
3. The consensus of classical and well-known scholars in Fiqh (with reference if available)

$appContext

⚠️ IMPORTANT GUIDELINES:
• Never invent rulings, interpretations, or personal opinions
• If a question has no clear authentic source, say: "This matter requires guidance from a qualified scholar. Please consult a local imam or scholar."
• Reference specific app features when they can help the user
• Use the user's prayer statistics to provide personalized encouragement and guidance
• Consider the user's location and current prayer times for relevant advice

ANSWERING STYLE:
• Be clear, respectful, and concise
• Always prioritize authenticity over convenience
• Use an educational and respectful tone
• Provide personalized guidance based on the user's spiritual journey
• Reference specific Noor app features that can help with their question

ANSWERING RULES:
• Always cite your source (Qur'an verse, Hadith book + number, scholar's name)
• If multiple opinions exist, mention them briefly and note which are stronger according to scholars
• Always begin answers with Bismillah or a respectful greeting (like Assalamu Alaikum)
• When quoting Hadith/Qur'an, also give translation in English
• End with actionable suggestions using Noor app features when relevant
• Use prayer statistics to provide encouraging or motivational advice

User's question: $userMessage

Please provide a comprehensive, authentic Islamic response that leverages the user's data and app features for maximum benefit.''';
  }

  String _buildConversationalContext(String userMessage) {
    return '''You are a friendly Islamic AI assistant named Noor. You are knowledgeable about Islam and should provide authentic guidance based on Quran and Sunnah.

CONVERSATION STYLE:
• Be warm, friendly, and conversational
• Keep responses concise unless asked for detailed explanations
• Use natural, flowing conversation
• Start with Islamic greetings when appropriate
• Be encouraging and supportive
• Only mention app features if directly relevant to the question

ISLAMIC GUIDELINES:
• Base answers on authentic Islamic sources
• Always prioritize Quran and authentic Hadith
• If unsure about a ruling, recommend consulting a scholar
• Use respectful Islamic language and terminology

User's message: $userMessage

Respond in a friendly, conversational way while maintaining Islamic authenticity. Keep it concise unless they specifically ask for detailed information.''';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _ChatBubble(message: message);
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.psychology, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Islamic AI Assistant',
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              Text(
                'Powered by Gemini',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _showApiKeyDialog,
          icon: const Icon(Icons.settings),
          tooltip: 'API Settings',
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.psychology, size: 18, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Thinking',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary.withOpacity(_typingAnimation.value),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ...List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.only(left: 2),
                        child: Text(
                          '•',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary.withOpacity(
                              (_typingController.value + (index * 0.3)) % 1.0,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.textTertiary, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Ask about Islam, Quran, Hadith, prayers...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.textTertiary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                enabled: !_isLoading,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      _isLoading ? Icons.hourglass_bottom : Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Key Settings'),
        content: const Text('Would you like to change your API key?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AiSetupScreen()),
              );
            },
            child: const Text('Change API Key'),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.psychology, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.isUser
                ? SelectableText(
                    message.text,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      height: 1.4,
                    ),
                  )
                : MarkdownBody(
                    data: message.text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.4,
                      ),
                      h1: AppTextStyles.heading1.copyWith(
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                      h2: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                      h3: AppTextStyles.heading3.copyWith(
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                      strong: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                      em: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      code: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accent,
                        backgroundColor: AppColors.background,
                        fontFamily: 'monospace',
                      ),
                      blockquote: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                      blockquoteDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border(
                          left: BorderSide(
                            color: AppColors.primary,
                            width: 3,
                          ),
                        ),
                      ),
                      listBullet: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        height: 1.4,
                      ),
                      tableHead: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      tableBody: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      tableBorder: TableBorder.all(
                        color: AppColors.textTertiary,
                        width: 1,
                      ),
                    ),
                  ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.secondary,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
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
