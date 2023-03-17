import 'dart:ui';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  bool _displayLoadingScreen = false;
  bool _showResultButton = false;
  late BannerAd _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/2934735716', // テスト広告ユニットID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) async {
    _textEditingController.clear();
    setState(() {
      _messages.add({"role": "user", "content": text});
      _displayLoadingScreen = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    String response;
    try {
      response = await _apiClient.generateResponse(_messages);
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _showResultButton = true;
      });
    } catch (e) {
      response = 'Error: Could not generate a response.';
      setState(() {
        _messages.add({"role": "assistant", "content": response});
        _showResultButton = true;
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

  void _resetLoadingScreen() {
    setState(() {
      _displayLoadingScreen = false;
      _showResultButton = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chat',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 40,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.menu, color: Colors.purple, size: 32),
            padding: const EdgeInsets.all(0),
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
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
      body: Stack(
        children: [
          SafeArea(
              child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
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
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(15),
                            topRight: const Radius.circular(15),
                            bottomLeft: isUserMessage
                                ? const Radius.circular(15)
                                : const Radius.circular(4),
                            bottomRight: isUserMessage
                                ? const Radius.circular(4)
                                : const Radius.circular(15),
                          ),
                          gradient: isUserMessage
                              ? const LinearGradient(
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                  colors: [
                                      Colors.purple,
                                      Colors.deepPurpleAccent
                                    ])
                              : null,
                          color: !isUserMessage ? Colors.grey[300] : null,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[200],
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          onSubmitted: _handleSubmitted,
                          decoration: const InputDecoration(
                            hintText: 'Send a message',
                            contentPadding: EdgeInsets.all(10),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () =>
                          _handleSubmitted(_textEditingController.text),
                    ),
                  ],
                ),
              ),
            ],
          )),
          // _displayLoadingScreenがtrueの間だけ、ぼかし効果と広告、テキスト、ローディングアイコンを表示
          if (_displayLoadingScreen)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isAdLoaded) // 広告がロードされた場合にのみAdWidgetを表示する
                          AdWidget(ad: _bannerAd),
                        const SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          height: MediaQuery.of(context).size.height * 0.2,
                          color: Colors.white,
                          child: const Center(
                            child: Text(
                              'Ad goes here',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          '考え中...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (!_showResultButton)
                          const SpinKitCircle(
                            color: Colors.white,
                            size: 50.0,
                          )
                        else
                          InkWell(
                            onTap: _resetLoadingScreen,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [
                                    Colors.purple,
                                    Colors.deepPurpleAccent,
                                  ],
                                ),
                              ),
                              child: const Text(
                                '返答を見る',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
