import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 1. Put your Gemini API Key here
  static const String _apiKey = 'AIzaSyDt38eSk59FMXJV-7qrnGg1__75clcvJR4'; 

  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  late final GenerativeModel _model;
  late final ChatSession _chatSession;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  void _initializeAI() {
    // 2. The System Prompt: This is the "Brain" and "Rulebook" for your Concierge
    final systemInstruction = Content.system('''
      You are the official AI Concierge for the NorthCare Property Management System. 
      You manage three apartment buildings in Bacolod City: D’ NorthGate, D’ NorthWay, and NorthPoint Atrium.
      
      Your role is to help prospective renters and current tenants.
      Tone: Professional, welcoming, concise, and helpful.

      Knowledge Base:
      - Location: All properties are located along BS Aquino Drive, Bacolod City, near the University of St. La Salle, The Doctors’ Hospital, and Riverside Medical Center.
      - Unit Types: We offer Studios, 1-Bedroom, and 2-Bedroom units. (Do not invent exact prices, tell them prices vary and to submit an inquiry).
      - Pet Policy: Small pets are allowed with prior management approval and a pet deposit.
      - Maintenance: If a user asks about fixing something broken, tell them to use the "Report Maintenance Issue" form on the home screen.
      - Viewings: If a user wants to rent or see a room, tell them to use the "Submit Unit Inquiry" form on the home screen.
      
      Important: Do NOT invent information. If you don't know the answer, politely say that the property manager will be happy to answer that if they submit an inquiry form.
    ''');

    // 3. Initialize the Gemini Model
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
    );

    // Start the chat session so it remembers conversation history
    _chatSession = _model.startChat();

    // Add the initial greeting message to the UI
    _messages.add(ChatMessage(
      text: "Hello! I am the NorthCare AI Concierge. How can I help you with D’ NorthGate, D’ NorthWay, or NorthPoint Atrium today?",
      isUser: false,
    ));
  }

  Future<void> _sendMessage() async {
    final userText = _controller.text.trim();
    if (userText.isEmpty) return;

    // Add user message to UI and clear the text field
    setState(() {
      _messages.add(ChatMessage(text: userText, isUser: true));
      _isLoading = true;
    });
    _controller.clear();

    try {
      // 4. Send the message to Gemini and wait for the response
      final response = await _chatSession.sendMessage(Content.text(userText));
      
      final aiText = response.text ?? "I'm sorry, I couldn't process that. Please try again.";

      // Add AI response to UI
      setState(() {
        _messages.add(ChatMessage(text: aiText, isUser: false));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Oops! I'm having trouble connecting to my database right now. Please try again later.",
          isUser: false,
        ));
      });
      print("Chat Error: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Concierge'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // The Chat Transcript
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser ? Colors.teal : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                        bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),

          // The Input Field area
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, -2))
              ]
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about units, rules, etc...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}