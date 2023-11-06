import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../ChatContent/message_list.dart';

// Model for chat messages


// Widget for displaying individual chat messages
class ChatMessageWidget extends StatelessWidget {
  final String messageContent;
  final String messageType;

  const ChatMessageWidget({
    Key? key,
    required this.messageContent,
    required this.messageType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 14, right: 14, top: 10, bottom: 10),
      child: Align(
        alignment: (messageType == "receiver" ? Alignment.topLeft : Alignment.topRight),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: (messageType == "receiver" ? Colors.grey.shade200 : Colors.blue[200]),
          ),
          padding: EdgeInsets.all(16),
          child: Text(
            messageContent,
            style: TextStyle(fontSize: 15),
          ),
        ),
      ),
    );
  }
}

// Main Chat Page Widget
class ChatMessages extends StatefulWidget {
  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  IO.Socket? socket;
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _sendMessage() {
    final String newMessageContent = messageController.text.trim();
    if (newMessageContent.isNotEmpty) {
      var message = {
        'content': newMessageContent,
        'sender': 'YourSenderIdentifier' // Replace with actual sender identifier
      };

      print("Sending: $message");
      socket?.emit('sendMessage', message);
      messageController.clear();

      // Add the message to the message list and scroll to the bottom
      setState(() {
        messages.add(ChatMessage(
          messageContent: newMessageContent,
          messageType: 'sender',
        ));
        _scrollToBottom();
      });
    }
  }

  void _initSocket() {
    // Make sure to replace with your actual server URL
    socket = IO.io('https://8cc2-49-145-135-84.ngrok-free.app:3000', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    socket?.connect();

    socket?.onConnect((_) {
      print('connected to socket server');
    });

    socket?.onConnectError((data) {
      print('Connection Error: $data');
    });

    socket?.onError((data) {
      print('Error: $data');
    });

    socket?.on('receiveMessage', (data) {
      _onReceiveMessage(data);
    });
  }

  void _onReceiveMessage(dynamic data) {
    print("Received: $data");
    setState(() {
      messages.add(ChatMessage(
        messageContent: data['content'],
        messageType: data['sender'] == 'YourSenderIdentifier' ? 'sender' : 'receiver',
      ));
      _scrollToBottom(); // Scroll to the bottom whenever a new message is received
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Detail"),
        elevation: 0,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        flexibleSpace: SafeArea(
          child: Container(
            padding: EdgeInsets.only(right: 16),
            child: Row(
              children: <Widget>[
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                ),
                SizedBox(width: 2),
                CircleAvatar(
                  backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/5.jpg"),
                  maxRadius: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Kriss Benwat", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      SizedBox(height: 6),
                      Text("Online", style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          ListView.builder(
            itemCount: messages.length,
            shrinkWrap: true,
            padding: EdgeInsets.only(top: 10, bottom: 70),
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return ChatMessageWidget(
                messageContent: messages[index].messageContent,
                messageType: messages[index].messageType,
              );
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: EdgeInsets.only(left: 10, bottom: 10, top: 10),
              height: 60,
              width: double.infinity,
              color: Colors.white,
              child: Row(
                children: <Widget>[
                  SizedBox(width: 1),
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: "Write message...",
                        hintStyle: TextStyle(color: Colors.black54),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  FloatingActionButton(
                    onPressed: _sendMessage,
                    child: Icon(Icons.send, color: Colors.white, size: 18),
                    backgroundColor: Colors.blue,
                    elevation: 0,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
