import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ignore: use_key_in_widget_constructors
class HomeScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  bool playAudio = true;
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _sendRequest(String userPrompt) async {
    var response = await http.post(
      Uri.parse('http://192.168.29.13:5000/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': userPrompt}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        chatHistory.add({'role': 'user', 'content': userPrompt});
        chatHistory.add({'role': 'assistant', 'content': data['response']});
        if (playAudio) _playAudio(data['audio']);
      });
    } else {
      // ignore: avoid_print
      print("Error: ${response.statusCode}");
    }
  }

  Future<void> _playAudio(String base64Audio) async {
    Uint8List audioBytes = base64.decode(base64Audio);
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(BytesSource(audioBytes));
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => setState(() {
        _isListening = val == "listening";
      }),
      onError: (val) => setState(() {
        _isListening = false;
      }),
    );

    if (available) {
      _speech.listen(
        localeId: 'bn_BD', // Bengali locale for speech recognition
        onResult: (val) => setState(() {
          _controller.text = val.recognizedWords;
        }),
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF2E2E2E),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 235, 121, 237),
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.0),
              child: Image.asset(
                'assets/logo.png',
                height: 40,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'BHAV - AI',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Comic Sans MS',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatHistory.length,
              itemBuilder: (context, index) {
                final message = chatHistory[index];
                return ListTile(
                  title: Align(
                    alignment: message['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user' ? Colors.white : Colors.black,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        message['content'] ?? '',
                        style: TextStyle(
                          color: message['role'] == 'user' ? Colors.black : Colors.white,
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
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'আপনার প্রশ্ন লিখুন...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 235, 121, 237),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _sendRequest(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: Icon(Icons.send, color: Colors.white),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(12),
                  ),
                  onPressed: _isListening ? _stopListening : _startListening,
                  child: Icon(
                    _isListening ? Icons.mic_off : Icons.mic,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Audio Playback:",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Switch(
                activeColor: Color.fromARGB(255, 235, 121, 237),
                value: playAudio,
                onChanged: (bool value) {
                  setState(() {
                    playAudio = value;
                  });
                },
              ),
              SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  setState(() {
                    chatHistory.clear();
                  });
                },
                icon: Icon(Icons.delete, color: Colors.white),
                label: Text(
                  "Clear Chat",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
