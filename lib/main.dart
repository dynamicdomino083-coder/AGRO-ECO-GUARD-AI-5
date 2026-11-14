
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgroEcoGuardApp());
}

class AgroEcoGuardApp extends StatelessWidget {
  const AgroEcoGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGRO ECO GUARD AI 5.0',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF07150F),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF20C878),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    DashboardPage(),
    AIChatPage(),
    AgriculturePage(),
    FounderPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF10251A),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Mode',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Agriculture',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Founder',
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Widget featureCard(
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Card(
      color: const Color(0xFF12291D),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF36D98B), size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const SizedBox(height: 18),
        const Icon(Icons.eco, size: 65, color: Color(0xFF36D98B)),
        const SizedBox(height: 12),
        const Text(
          'AGRO ECO GUARD',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const Text(
          'ARTIFICIAL INTELLIGENCE 5.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF36D98B), letterSpacing: 2),
        ),
        const SizedBox(height: 25),
        const Text('Welcome to your Smart Agriculture System',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16)),
        const SizedBox(height: 20),
        featureCard(Icons.psychology, 'Universal AI Mode',
            'Ask questions and communicate with AI.'),
        featureCard(Icons.mic, 'Voice Assistant',
            'Speak and listen using supported phone languages.'),
        featureCard(Icons.agriculture, 'Smart Agriculture',
            'Agriculture information and sensor monitoring.'),
        featureCard(Icons.sensors, 'ESP32 Connection',
            'Waiting for real ESP32 sensor data.'),
        featureCard(Icons.language, 'Multilingual Support',
            'Hindi, Odia, English and more.'),
        const SizedBox(height: 20),
        const Text(
          'Founded & Developed by MUHAYUDDIN GAUS',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF36D98B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  final stt.SpeechToText speech = stt.SpeechToText();
  final FlutterTts tts = FlutterTts();

  final List<ChatMessage> messages = [];

  bool isListening = false;
  bool isLoading = false;
  bool voiceEnabled = true;

  double speechRate = 0.48;
  double voicePitch = 1.0;

  String selectedLanguage = 'English';

  // Replace this with your own secure HTTPS Python backend URL.
  // Never put a private API key in this public GitHub repository.
  static const String backendUrl =
      'https://YOUR-SECURE-BACKEND-URL/api/ask';

  final Map<String, String> languageNames = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Odia': 'or-IN',
    'Punjabi': 'pa-IN',
    'Urdu': 'ur-PK',
    'Arabic': 'ar-SA',
    'Roman English': 'en-US',
    'Roman Odia': 'or-IN',
  };

  @override
  void initState() {
    super.initState();
    initializeVoice();
    messages.add(ChatMessage(
      text:
          'Welcome to AGRO ECO GUARD AI 5.0! Ask me a question about agriculture, science, technology, education or general knowledge. Connect the secure AI backend to receive real AI answers.',
      isUser: false,
    ));
  }

  Future<void> initializeVoice() async {
    await speech.initialize();
    await tts.setSpeechRate(speechRate);
    await tts.setPitch(voicePitch);
  }

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (!available) {
      showNotice('Speech recognition is not available on this device.');
      return;
    }

    setState(() => isListening = true);

    await speech.listen(
      localeId: languageNames[selectedLanguage],
      listenFor: const Duration(seconds: 45),
      pauseFor: const Duration(seconds: 5),
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          messageController.text = result.recognizedWords;
          messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: messageController.text.length),
          );
        });
      },
    );
  }

  Future<void> stopListening() async {
    await speech.stop();
    if (mounted) {
      setState(() => isListening = false);
    }
  }

  Future<void> speakAnswer(String answer) async {
    if (!voiceEnabled) return;

    await tts.setLanguage(languageNames[selectedLanguage]!);
    await tts.setSpeechRate(speechRate);
    await tts.setPitch(voicePitch);
    await tts.speak(answer);
  }

  void showNotice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Future<void> sendMessage() async {
    final question = messageController.text.trim();

    if (question.isEmpty || isLoading) return;

    setState(() {
      messages.add(ChatMessage(text: question, isUser: true));
      messageController.clear();
      isLoading = true;
    });

    scrollToBottom();

    try {
      final response = await http
          .post(
            Uri.parse(backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              'language': selectedLanguage,
              'application': 'AGRO ECO GUARD AI 5.0',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);

        String answer = 'The AI server returned an empty answer.';

        if (decoded is Map) {
          answer = (decoded['answer'] ??
                  decoded['response'] ??
                  decoded['message'] ??
                  answer)
              .toString();
        }

        if (mounted) {
          setState(() {
            messages.add(ChatMessage(text: answer, isUser: false));
          });
          await speakAnswer(answer);
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text:
                'AI connection is not ready. Please check the Python backend URL and internet connection. No AI answer was generated. Details: $error',
            isUser: false,
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        scrollToBottom();
      }
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> showVoiceSettings() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF10251A),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('VOICE SETTINGS',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Voice Replies'),
                    value: voiceEnabled,
                    onChanged: (value) {
                      setSheetState(() => voiceEnabled = value);
                      setState(() => voiceEnabled = value);
                      if (!value) tts.stop();
                    },
                  ),
                  const SizedBox(height: 10),
                  const Text('Voice Speed'),
                  Slider(
                    value: speechRate,
                    min: 0.2,
                    max: 0.8,
                    onChanged: (value) {
                      setSheetState(() => speechRate = value);
                      setState(() => speechRate = value);
                    },
                  ),
                  const Text('Voice Pitch'),
                  Slider(
                    value: voicePitch,
                    min: 0.5,
                    max: 2.0,
                    onChanged: (value) {
                      setSheetState(() => voicePitch = value);
                      setState(() => voicePitch = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await speakAnswer('Voice settings are ready.');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Voice'),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget buildMessage(ChatMessage message) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 310),
        decoration: BoxDecoration(
          color: message.isUser
              ? const Color(0xFF176B43)
              : const Color(0xFF173024),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message.text),
            if (!message.isUser)
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Listen',
                  onPressed: () => speakAnswer(message.text),
                  icon: const Icon(Icons.volume_up,
                      color: Color(0xFF36D98B)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
          child: Row(
            children: [
              const Icon(Icons.psychology,
                  color: Color(0xFF36D98B), size: 32),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UNIVERSAL AI MODE',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('AGRO ECO GUARD AI 5.0',
                        style: TextStyle(color: Colors.white60)),
                  ],
                ),
              ),
              IconButton(
                onPressed: showVoiceSettings,
                icon: const Icon(Icons.tune),
                tooltip: 'Voice Settings',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonFormField<String>(
            value: selectedLanguage,
            decoration: const InputDecoration(
              labelText: 'Choose Language',
              border: OutlineInputBorder(),
            ),
            items: languageNames.keys.map((language) {
              return DropdownMenuItem(
                value: language,
                child: Text(language),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => selectedLanguage = value);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.all(14),
            itemCount: messages.length,
            itemBuilder: (context, index) =>
                buildMessage(messages[index]),
          ),
        ),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text('Connecting to AI...'),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
          child: Row(
            children: [
              IconButton.filledTonal(
                onPressed: isListening ? stopListening : startListening,
                icon: Icon(isListening ? Icons.mic_off : Icons.mic),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: messageController,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ask anything...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: isLoading ? null : sendMessage,
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    speech.stop();
    tts.stop();
    super.dispose();
  }
}

class AgriculturePage extends StatelessWidget {
  const AgriculturePage({super.key});

  Widget sensorCard(String name, String value, IconData icon) {
    return Card(
      color: const Color(0xFF12291D),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF36D98B)),
        title: Text(name),
        subtitle: Text(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const Text('SMART AGRICULTURE',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text('ESP32 Sensor Monitoring'),
        const SizedBox(height: 15),
        sensorCard('Soil Moisture',
            'Waiting for real ESP32 sensor data', Icons.water_drop),
        sensorCard('Temperature',
            'Waiting for real ESP32 sensor data', Icons.thermostat),
        sensorCard('Humidity',
            'Waiting for real ESP32 sensor data', Icons.cloud),
        sensorCard('Rain Sensor',
            'Waiting for real ESP32 sensor data', Icons.water),
        sensorCard('MQ-4 Gas Sensor',
            'Waiting for real ESP32 sensor data', Icons.air),
        sensorCard('GPS Location',
            'Waiting for real ESP32 sensor data', Icons.location_on),
        sensorCard('PIR Motion Sensor',
            'Waiting for real ESP32 sensor data', Icons.sensors),
        sensorCard('Ultrasonic Sensor',
            'Waiting for real ESP32 sensor data', Icons.radar),
        const SizedBox(height: 15),
        const Text(
          'Sensor values will appear after the ESP32 connection is configured.',
          style: TextStyle(color: Colors.white60),
        ),
      ],
    );
  }
}

class FounderPage extends StatelessWidget {
  const FounderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 48,
              backgroundColor: Color(0xFF176B43),
              child: Icon(Icons.person, size: 55, color: Colors.white),
            ),
            const SizedBox(height: 25),
            const Text(
              'FOUNDER & DEVELOPER',
              style: TextStyle(
                color: Color(0xFF36D98B),
                letterSpacing: 2,
            
