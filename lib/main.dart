import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'api_client.dart';

void main() async {
  await dotenv.load();
  runApp(ChatGPTApp());
}

class ChatGPTApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChatScreen(),
    );
  }
}

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
      appBar: AppBar(title: Text('Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                    title: MarkdownBody(
                  data:
                      '${_messages[index]['role']}: ${_messages[index]['content']}',
                ));
              },
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textEditingController,
                    onSubmitted: _handleSubmitted,
                    decoration:
                        InputDecoration.collapsed(hintText: 'Send a message'),
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
          Container(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _clearMessages,
              child: Text('Clear Messages'),
            ),
          ),
        ],
      ),
    );
  }
}
