import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs().then((_) {
      _loadMessages();
    });
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Load chat messages from SharedPreferences
  void _loadMessages() {
    print("Loading messages...");
    final String messagesString = _prefs.getString('messages') ?? '[]';

    if (messagesString.isNotEmpty) {
      final List<dynamic> messagesData = jsonDecode(messagesString);
      final List<ChatMessage> messages = messagesData
          .map((message) => ChatMessage.fromJson(message))
          .toList();

      setState(() {
        _messages.addAll(messages);
      });
    }
  }


  // Save chat messages to SharedPreferences
  Future<void> _saveMessages() async {
    print("Saving messages...");
    final List<Map<String, dynamic>> messagesData =
    _messages.map((message) => message.toJson()).toList();
    final String messagesString = jsonEncode(messagesData);
    await _prefs.setString('messages', messagesString);
  }

  @override
  void dispose() {
    _saveMessages(); // Save messages when the widget is disposed
    super.dispose();
  }

  //Get an instance of OpenAI and setup HTTP
  final _openAI = OpenAI.instance.build(
    token: OPENAI_API_KEY,
    baseOption: HttpSetup(
      receiveTimeout: const Duration(seconds: 20),
    ),
    enableLog: true,
  );

  final ChatUser _currentUser = ChatUser(
      id: '1', firstName: 'Shegs', lastName: 'AppGuy');
  final ChatUser _gptUser = ChatUser(
      id: '2', firstName: 'Companion', lastName: 'AI');

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

  //When the user sends a message, the getChatResponse method is invoked with the ChatMessage as a parameter.
  Future<void> getChatResponse(ChatMessage message) async {
    try {
      setState(() {
        //the _messages list is updated to include the user's message
        _messages.insert(0, message);
        _typingUsers.add(_gptUser);
      });

      //The message history is then constructed from the _messages list.
      // Each message is converted into a Messages object
      // with a role (user or assistant) and content.
      List<Messages> _messagesHistory = _messages.reversed.map((message) {
        if (message.user == _currentUser) {
          return Messages(role: Role.user, content: message.text);
        } else {
          return Messages(role: Role.assistant, content: message.text);
        }
      }).toList();

      //Then I specified the GPT model with other parameter in a request
      final request = ChatCompleteText(
        model: GptTurbo0301ChatModel(),
        messages: _messagesHistory,
        maxToken: 120,
        temperature: 1,
        presencePenalty: 1,
        frequencyPenalty: 1,
      );

      final response = await _openAI.onChatCompletion(request: request);

      //The response from the network call is processed.
      // For each choice in the response, if there is a message,
      // a new ChatMessage with the GPT user and the generated content
      // is inserted into the _messages list.
      for (var element in response!.choices) {
        if (element.message != null) {
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

      _saveMessages();

      //Finally, the GPT user is removed from the
      // _typingUsers list to indicate that the assistant has finished typing.
      setState(() {
        _typingUsers.remove(_gptUser);
      });
    } catch (e) {
      // Check if the exception is a server error
      if (e.toString().toLowerCase().contains('server error')) {
        // Handle server error: Display a message to the user with details
        showServerErrorToUser("There is a server error");
      } else if (e is TimeoutException) {
        // Handle timeout: Display a message to the user to resend the last message
        showTimeoutErrorToUser();
      } else {
        // Handle other network errors
        print("Error during network request: $e");
        // Display a generic error message to the user
        showErrorToUser();
      }
    } finally {
      // Remove _gptUser from _typingUsers regardless of the error type
      setState(() {
        _typingUsers.remove(_gptUser);
      });
    }
  }

  void showServerErrorToUser(String serverMessage) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          user: _gptUser,
          createdAt: DateTime.now(),
          text: "Not you, there's an error from my end: $serverMessage. Please try again later.",
        ),
      );
    });
  }

  void showTimeoutErrorToUser() {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          user: _gptUser,
          createdAt: DateTime.now(),
          text: "Awchhh, Not now! Your request just timed out. Please resend your last message.",
        ),
      );
    });
  }

  void showErrorToUser() {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          user: _gptUser,
          createdAt: DateTime.now(),
          text: "Oops, there was an error. Please check your internet connection and send last message.",
        ),
      );
    });
  }
}
