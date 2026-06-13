import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/ai_coach_service.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/providers/workout_providers.dart';

class GymAiChatScreen extends ConsumerStatefulWidget {
  const GymAiChatScreen({super.key});

  @override
  ConsumerState<GymAiChatScreen> createState() => _GymAiChatScreenState();
}

class _GymAiChatScreenState extends ConsumerState<GymAiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _messages.add(_ChatMessage(
      text: "Hey! I'm your GymAI coach. Ask me anything about training, or capture a food photo for instant macro analysis! 💪",
      isUser: false,
    ));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider);
      final sessions = ref.read(sessionsProvider);
      AiCoachService.instance.initialize(profile, sessions);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    String fullResponse = "";
    final botMessage = _ChatMessage(text: "", isUser: false);
    setState(() => _messages.add(botMessage));

    await for (final chunk in AiCoachService.instance.sendMessage(text)) {
      fullResponse += chunk;
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(text: fullResponse, isUser: false);
      });
      _scrollToBottom();
    }

    setState(() => _isTyping = false);
  }

  Future<void> _handleImagePick() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.cardElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: AppColors.blueLight),
              title: Text('Take Photo', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: AppColors.blueLight),
              title: Text('Choose from Gallery', style: GoogleFonts.inter(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image == null) return;

    final bytes = await image.readAsBytes();
    
    setState(() {
      _messages.add(_ChatMessage(
        text: "Analyzing this meal... 🔍",
        isUser: true,
        imageBytes: bytes,
      ));
      _isTyping = true;
    });
    _scrollToBottom();

    String fullResponse = "";
    final botMessage = _ChatMessage(text: "", isUser: false);
    setState(() => _messages.add(botMessage));

    await for (final chunk in AiCoachService.instance.analyzeFoodImage(bytes)) {
      fullResponse += chunk;
      setState(() {
        _messages[_messages.length - 1] = _ChatMessage(text: fullResponse, isUser: false);
      });
      _scrollToBottom();
    }

    setState(() => _isTyping = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.background,
              AppColors.blueMuted.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _ChatBubble(
                    message: _messages[index],
                    isLast: index == _messages.length - 1,
                  );
                },
              ),
            ),
            if (_isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('GymAI is typing...', 
                    style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic)),
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Column(
            children: [
              Text('GYM AI COACH', 
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  letterSpacing: 2
                ),
              ),
              Container(
                height: 2,
                width: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueLight]),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardElevated.withValues(alpha: 0.9),
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              IconButton(
                onPressed: _isTyping ? null : _handleImagePick,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.blueLight, size: 20),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    onSubmitted: (_) => _handleSend(),
                    decoration: InputDecoration(
                      hintText: 'Ask your coach...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isTyping ? null : _handleSend,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.blue, AppColors.blueDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.blue.withValues(alpha: 0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final Uint8List? imageBytes;

  _ChatMessage({required this.text, required this.isUser, this.imageBytes});
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;
  final bool isLast;
  
  const _ChatBubble({required this.message, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Align(
        alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
          child: Stack(
            children: [
              // Glassmorphic background
              ClipRRect(
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                  bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: message.isUser 
                        ? AppColors.blue.withValues(alpha: 0.15) 
                        : AppColors.cardElevated.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                        bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                      ),
                      border: Border.all(
                        color: message.isUser 
                          ? AppColors.blue.withValues(alpha: 0.3) 
                          : AppColors.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.imageBytes != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  Image.memory(message.imageBytes!, height: 200, width: double.infinity, fit: BoxFit.cover),
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, height: 1.6),
                            h1: GoogleFonts.rajdhani(color: AppColors.blueLight, fontSize: 20, fontWeight: FontWeight.bold),
                            h2: GoogleFonts.rajdhani(color: AppColors.blueLight, fontSize: 18, fontWeight: FontWeight.bold),
                            h3: GoogleFonts.rajdhani(color: AppColors.blueLight, fontSize: 16, fontWeight: FontWeight.bold),
                            strong: GoogleFonts.inter(color: AppColors.blueLight, fontWeight: FontWeight.bold),
                            em: GoogleFonts.inter(fontStyle: FontStyle.italic),
                            listBullet: GoogleFonts.inter(color: AppColors.blueLight),
                            blockquote: GoogleFonts.inter(color: AppColors.textSecondary),
                            code: GoogleFonts.robotoMono(
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              color: AppColors.goldLight,
                              fontSize: 12,
                            ),
                            tableBody: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 12),
                            tableHead: GoogleFonts.inter(color: AppColors.blueLight, fontSize: 12, fontWeight: FontWeight.bold),
                            tableBorder: TableBorder.all(color: AppColors.border, width: 0.5),
                            tableCellsPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Subtle accent glow for AI
              if (!message.isUser)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blue.withValues(alpha: 0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
