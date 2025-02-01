import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, String>> chatHistory = [];
  bool playAudio = true;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool isGenerating = false;
  String? emergencyNumber;
  bool settingsExpanded = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _sendRequest(String userPrompt) async {
    if (isGenerating) return;
    
    setState(() {
      isGenerating = true;
    });

    var response = await http.post(
      Uri.parse('https://bhav-xd21.onrender.com/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': userPrompt}),
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      setState(() {
        chatHistory.add({'role': 'user', 'content': userPrompt});
        chatHistory.add({'role': 'assistant', 'content': data['response']});
        if (playAudio) _playAudio(data['audio']);
        emergencyNumber = data['call'];
      });

      if (emergencyNumber != null && emergencyNumber!.isNotEmpty) {
        _dialEmergencyNumber(emergencyNumber!);
      }
    }
    setState(() {
      isGenerating = false;
    });
  }

  Future<void> _playAudio(String base64Audio) async {
    Uint8List audioBytes = base64.decode(base64Audio);
    AudioPlayer audioPlayer = AudioPlayer();
    await audioPlayer.play(BytesSource(audioBytes));
  }

  Future<void> _dialEmergencyNumber(String number) async {
    final intent = AndroidIntent(
      action: 'android.intent.action.DIAL',
      data: 'tel:$number',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
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
        localeId: 'bn_BD',
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
      backgroundColor: Color(0xFF121212), // Dark background
      appBar: AppBar(
        backgroundColor: Color(0xFF1E88E5), // Blue
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'assets/logo.png',
                height: 30,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(width: 10),
            Text('BHAV - AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: IconButton(
          icon: Icon(settingsExpanded ? Icons.close : Icons.settings, color: Colors.white),
          onPressed: () {
            setState(() {
              settingsExpanded = !settingsExpanded;
            });
          },
        ),
      ),
      body: Column(
        children: [
          if (settingsExpanded)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Audio Playback:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      Switch(
                        activeColor: Color(0xFF8E24AA), // Purple
                        value: playAudio,
                        onChanged: (bool value) {
                          setState(() {
                            playAudio = value;
                          });
                        },
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFD32F2F)), // Red
                    onPressed: () {
                      setState(() {
                        chatHistory.clear();
                      });
                    },
                    icon: Icon(Icons.delete, color: Colors.white),
                    label: Text("Clear Chat", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: chatHistory.length + (isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (isGenerating && index == chatHistory.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(color: Color(0xFF8E24AA)), // Purple
                    ),
                  );
                }
                final message = chatHistory[index];
                return ListTile(
                  title: Align(
                    alignment: message['role'] == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: message['role'] == 'user' ? Color(0xFF64B5F6) : Color(0xFF512DA8), // Light Blue for user, Dark Purple for assistant
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        message['content'] ?? '',
                        style: TextStyle(color: message['role'] == 'user' ? Colors.black : Colors.white),
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
                  onPressed: isGenerating ? null : () {
                    if (_controller.text.isNotEmpty) {
                      _sendRequest(_controller.text);
                      _controller.clear();
                    }
                  },
                  child: Icon(Icons.send, color: Colors.white),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF3949AB)), // Blue
                  onPressed: _isListening ? _stopListening : _startListening,
                  child: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}