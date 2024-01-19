import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:juanapp/components/chat_bubble.dart';
import 'package:juanapp/components/my_textfield.dart';
import 'package:juanapp/services/auth/auth_service.dart';
import 'package:juanapp/services/chat/chat_service.dart';
import 'package:juanapp/services/audio/audio_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverID;

  const ChatPage(
      {super.key, required this.receiverEmail, required this.receiverID});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  //text controller
  final TextEditingController _messageController = TextEditingController();

  // chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final AudioService _audioService = AudioService();
  bool _isRecording = false;

  FocusNode myFocusNode = FocusNode();

  // for text field focus
  @override
  void initState() {
    super.initState();

    // add listener to focus node
    myFocusNode.addListener(() {
      if (myFocusNode.hasFocus) {
        // cause a delay to show keyboard
        Future.delayed(
          const Duration(milliseconds: 500),
          () => scrollDown(),
        );
      }
      _audioService.init(); // Initialize the audio service
    });

    @override
    void dispose() {
      // Dispose the audio service
      _audioService.dispose();
      super.dispose();
    }

    void toggleRecording() async {
      if (_isRecording) {
        final String? filePath = await _audioService.stopRecording();
        if (filePath != null) {
          final String? audioUrl =
              await _audioService.uploadAudioFile(filePath);
          if (audioUrl != null) {
            // Send the audio message
            await _chatService.sendAudioMessage(widget.receiverID, audioUrl);
          }
        }
      } else {
        await _audioService.startRecording();
      }
      setState(() {
        _isRecording = !_isRecording;
      });
    }

    Widget _recordButton() {
      return IconButton(
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        onPressed: toggleRecording,
        color: _isRecording ? Colors.red : Colors.blue,
      );
    }

    // wait for listview to show
    Future.delayed(
      const Duration(milliseconds: 500),
      () => scrollDown(),
    );
  }

  // scroll conttroller
  final ScrollController _scrollController = ScrollController();
  void scrollDown() {
    _scrollController.animateTo(_scrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
  }

  void sendMessage() async {
    // if there is something inside the textfield
    if (_messageController.text.isNotEmpty) {
      // send the message
      await _chatService.sendMessage(
          widget.receiverID, _messageController.text);

      // clear text controller
      _messageController.clear();
    }

    scrollDown();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(widget.receiverEmail),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.grey,
      ),
      body: Column(
        children: [
          // display all messages
          Expanded(
            child: _buildMessageList(),
          ),

          // user input
          _buildUserInput(),
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverID, senderID),
      builder: (context, snapshot) {
        // errors
        if (snapshot.hasError) {
          return const Text("Error");
        }

        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading...");
        }

        // return list view
        return ListView(
          controller: _scrollController,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // is current user
    bool isCurrentUser = data['senderID'] == _authService.getCurrentUser()!.uid;

    // align messages
    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ChatBubble(
            message: data["message"],
            isCurrentUser: isCurrentUser,
          ),
        ],
      ),
    );
  }

  // build message input
  Widget _buildUserInput() {
    void toggleRecording() async {
      if (_isRecording) {
        final String? filePath = await _audioService.stopRecording();
        if (filePath != null) {
          final String? audioUrl =
              await _audioService.uploadAudioFile(filePath);
          if (audioUrl != null) {
            // Send the audio message
            await _chatService.sendAudioMessage(widget.receiverID, audioUrl);
          }
        }
      } else {
        await _audioService.startRecording();
      }
      setState(() {
        _isRecording = !_isRecording;
      });
    }

    Widget _recordButton() {
      return IconButton(
        icon: Icon(_isRecording ? Icons.stop : Icons.mic),
        onPressed: toggleRecording,
        color: _isRecording ? Colors.red : Colors.blue,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 50.0),
      child: Row(
        children: [
          // textfield
          Expanded(
            child: MyTextField(
              controller: _messageController,
              hintText: "Type a message",
              obscureText: false,
              focusNode: myFocusNode,
            ),
          ),

          // send button
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 25),
            child: IconButton(
              onPressed: sendMessage,
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
              ),
            ),
          ),

          // send audio button
          _recordButton(),
        ],
      ),
    );
  }
}
