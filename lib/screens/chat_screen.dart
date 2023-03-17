import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../api_client.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      "role": "system",
      "content":
          "You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible. Knowledge cutoff: 2021-09-01 Current date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
    }
  ];
  final APIClient _apiClient = APIClient(apiKey: dotenv.env['OPENAI_API_KEY']!);
  final ScrollController _scrollController = ScrollController();

  void _handleSubmitted(String text) async {
    _textEditingController.clear();
    setState(() {
      _messages.add({"role": "user", "content": text});
    });

    String response;
    try {
      response = await _apiClient.generateResponse(_messages);
      setState(() {
        _messages.add({"role": "assistant", "content": response});
      });
    } catch (e) {
      response = 'Error: Could not generate a response.';
      setState(() {
        _messages.add({"role": "assistant", "content": response});
      });
    }
  }

  void _clearMessages() {
    setState(() {
      _messages.clear();
      _messages.add({
        "role": "system",
        "content":
            "You are ChatGPT, a large language model trained by OpenAI. Answer as concisely as possible. Knowledge cutoff: 2021-09-01 Current date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: Container(width: 0, height: 0),
          title: Text(
            'Chat',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            PopupMenuButton(
              icon: Icon(Icons.menu, color: Colors.purple),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'clear_messages',
                  child: Text(
                    'Clear Messages',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'clear_messages') {
                  _clearMessages();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
            child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  // 最初のプロンプトは非表示にする
                  if (index == 0) return Container();

                  final message = _messages[index];
                  final isUserMessage = message["role"] == "user";
                  return Container(
                    alignment: isUserMessage
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    padding: EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(15),
                          topRight: Radius.circular(15),
                          bottomLeft: isUserMessage
                              ? Radius.circular(15)
                              : Radius.circular(4),
                          bottomRight: isUserMessage
                              ? Radius.circular(4)
                              : Radius.circular(15),
                        ),
                        gradient: isUserMessage
                            ? LinearGradient(
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                                colors: [
                                    Colors.purple,
                                    Colors.deepPurpleAccent
                                  ])
                            : null,
                        color: !isUserMessage ? Colors.grey[300] : null,
                      ),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: SelectableText(
                        '${message["content"]}',
                        style: TextStyle(
                          color: isUserMessage ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.grey[200],
                      ),
                      child: TextField(
                        controller: _textEditingController,
                        onSubmitted: _handleSubmitted,
                        decoration: InputDecoration(
                          hintText: 'Send a message',
                          contentPadding: EdgeInsets.all(10),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () =>
                        _handleSubmitted(_textEditingController.text),
                  ),
                ],
              ),
            ),
          ],
        )));
  }
}
