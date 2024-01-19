import 'package:flutter/material.dart';
import 'package:juanapp/themes/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final String? audioUrl; 

  const ChatBubble({
    super.key, 
    required this.message, 
    required this.isCurrentUser, 
    this.audioUrl
  });

  @override
  Widget build(BuildContext context) {
    // light and dark mode
    bool isDarkMode = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    // Determine if the message is a text message or an audio message
    bool isAudioMessage = audioUrl != null;

    return Container(
      decoration: BoxDecoration(
          color: isCurrentUser
              ? (isDarkMode
                  ? const Color.fromARGB(255, 75, 158, 177)
                  : Colors.grey.shade500)
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
      child: isAudioMessage ? _buildAudioPlayer() : _buildTextMessage(isDarkMode),
    );
  }

  Widget _buildTextMessage(bool isDarkMode) {
    return Text(
      message,
      style: TextStyle(
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildAudioPlayer() {
    final player = AudioPlayer();
    return FutureBuilder(
      future: player.setUrl(audioUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: () => player.play(),
          );
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
