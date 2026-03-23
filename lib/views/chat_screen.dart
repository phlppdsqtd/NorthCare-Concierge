// lib/views/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodel/chat_viewmodel.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(ChatViewModel viewModel) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _scrollToBottom();
    await viewModel.sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ChatViewModel>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Concierge', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: viewModel.messages.length,
              itemBuilder: (context, index) {
                final message = viewModel.messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.teal : Colors.white,
                      boxShadow: [
                        if (!message.isUser)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                        bottomRight: Radius.circular(message.isUser ? 4 : 20),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (viewModel.isLoading)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, 
                    height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.teal.shade300)
                  ),
                  const SizedBox(width: 12),
                  Text('AI is thinking...', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ]
            ),
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 12, 
              bottom: MediaQuery.of(context).padding.bottom > 0 ? MediaQuery.of(context).padding.bottom : 12
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: 'Ask about units, pricing...',
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onSubmitted: (_) => _sendMessage(viewModel),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.teal,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    onPressed: viewModel.isLoading ? null : () => _sendMessage(viewModel),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}