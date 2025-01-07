import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workspace/services/chatbot_service.dart';
import 'package:workspace/components/theme_provider.dart';
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiChatbotService _chatbotService = GeminiChatbotService();
  bool _isBotTyping = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messages = prefs.getStringList('chat_messages');
    if (messages != null) {
      setState(() {
        _messages.addAll(messages.map((message) => Map<String, String>.from(json.decode(message))));
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messages = _messages.map((message) => json.encode(message)).toList();
    await prefs.setStringList('chat_messages', messages);
  }

  Future<void> _clearMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');
    setState(() {
      _messages.clear();
    });
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add({'sender': 'user', 'message': message});
      _isBotTyping = true;
    });

    _scrollToBottom();
    _saveMessages();

    try {
      final responseStream = _chatbotService.sendMessage(message);
      await for (var response in responseStream) {
        setState(() {
          _messages.add({'sender': 'bot', 'message': response});
        });
        _scrollToBottom();
        _saveMessages();
      }
    } catch (e) {
      setState(() {
        _messages.add({'sender': 'bot', 'message': 'Error: ${e.toString()}'});
      });
      _saveMessages();
    } finally {
      setState(() {
        _isBotTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'iSpark Chatbot',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF009688),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: _clearMessages,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (_isBotTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset(
                          'assets/animation/bot_typing.json',
                          width: 50,
                          height: 50,
                        ),
                        SizedBox(width: 10.0),
                        Text(
                          'Bot is typing...',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final message = _messages[index];
                final isUserMessage = message['sender'] == 'user';
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: isUserMessage
                        ? (isDarkMode ? Colors.teal[700] : Colors.teal[100])
                        : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10.0),
                      topRight: const Radius.circular(10.0),
                      bottomLeft: isUserMessage ? const Radius.circular(10.0) : const Radius.circular(0.0),
                      bottomRight: isUserMessage ? const Radius.circular(0.0) : const Radius.circular(10.0),
                    ),
                  ),
                  child: Align(
                    alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
                    child: MarkdownBody(
                      data: message['message']!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 16.0,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        strong: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Enter your message...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                    ),
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.send, color: const Color(0xFF009688)),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendMessage(_controller.text);
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFFAFAFA),
    );
  }
}
