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

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUsers = <ChatUser>[];

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
        typingUsers: _typingUsers,
        messageOptions: MessageOptions(
          currentUserContainerColor: Colors.green.shade400,
          containerColor: Colors.grey,
          textColor: Colors.white,
        ),
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage message) async {
    setState(() {
      _messages.insert(0, message);
      _typingUsers.add(_gptUser);
    });

    //Get messages history
    List<Messages> _messagesHistory = _messages.reversed.map((message) {
      if (message.user == _currentUser) {
        return Messages(role: Role.user, content: message.text);
      }else{
        return Messages(role: Role.assistant, content: message.text);
      }
    }).toList();
    
    final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: _messagesHistory,
      maxToken: 200,
    );

    final response = await _openAI.onChatCompletion(request: request);

    for (var element in response!.choices){
      if (element.message != null){
        setState(() {
          _messages.insert(0, ChatMessage(
              user: _gptUser,
              createdAt: DateTime.now(),
            text: element.message!.content,
          ),
          );
        });
      }
    }

    setState(() {
      _typingUsers.remove(_gptUser);
    });
  }
}
