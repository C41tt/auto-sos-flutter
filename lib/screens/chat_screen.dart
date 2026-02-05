// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'cloud_service.dart';
import '../constants/app_constants.dart'; // ⬅️ ИМПОРТ КОНСТАНТ

/// Экран чата с ИИ-помощником или Оператором
class ChatScreen extends StatefulWidget {
  final String sosId;
  
  const ChatScreen({super.key, required this.sosId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Текущий ID пользователя (заглушка)
  final String _currentUserId = 'driver_user';

  void _handleSend() async {
    if (_controller.text.trim().isNotEmpty) {
      final text = _controller.text.trim();
      _controller.clear();
      
      await CloudService.sendChatMessage(widget.sosId, _currentUserId, text);
    }
  }
  
  Widget _buildMessageBubble(String text, String sender) {
    final isMe = sender == _currentUserId;
    final isBot = sender == AppConstants.botSender || (sender != _currentUserId && sender.contains(AppConstants.workerRole));
    
    Color color;
    CrossAxisAlignment alignment;
    
    if (isMe) {
      color = Colors.blue.shade200;
      alignment = CrossAxisAlignment.end;
    } else if (isBot) {
      color = Colors.grey.shade300;
      alignment = CrossAxisAlignment.start;
    } else {
      color = Colors.green.shade200;
      alignment = CrossAxisAlignment.start;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.black87 : Colors.black,
              ),
            ),
          ),
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                sender == AppConstants.botSender ? 'Система' : 'Работник',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Введите сообщение...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (_) => _handleSend(),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).primaryColor,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _handleSend,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Чат SOS: ${widget.sosId}'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: CloudService.getChatMessages(widget.sosId),
              builder: (context, snapshot) {
                // ➡️ ИСПРАВЛЕНИЕ: Добавлена обработка ошибок
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка загрузки чата: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageBubble(message[AppConstants.text]!, message[AppConstants.sender]!);
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }
}