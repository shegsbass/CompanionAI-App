import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:companion_ai/consts.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final _openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 5),
    ),
    enableLog: true,
  );

  final ChatUser _currentUser = ChatUser(id: '1', firstName: 'Shegs', lastName: 'AppGuy');
  final ChatUser _gptUser = ChatUser(id: '2', firstName: 'Companion', lastName: 'AI');

  List<ChatMessage> _messages = <ChatMessage>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(8, 186, 126, 1),
        title: const Text(
          'Companion AI',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: DashChat(
        currentUser: _currentUser,
        onSend: (ChatMessage message) {
          getChatResponse(message);
        },
        messages: _messages,
        messageOptions: MessageOptions(
          currentUserContainerColor: Colors.green.shade400,
          containerColor: Colors.grey.shade300,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
    });
  }
}
