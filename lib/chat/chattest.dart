import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'ChatContent/message_list.dart';
import 'package:raamb_app/service/mongo_service.dart';
import 'dart:async';


// Model for chat messages

// Widget for displaying individual chat messages
class ChatMessageWidgetTest extends StatelessWidget {
  final String currentUserId; // Add this line
  final String senderId;
  final String receiverId;
  final String messageContent;
  final DateTime timestamp;
  final bool read;

  const ChatMessageWidgetTest({
    Key? key,
    required this.currentUserId, // Add this line
    required this.senderId,
    required this.receiverId,
    required this.messageContent,
    required this.timestamp,
    required this.read,
  }) : super(key: key);
  // ... rest of your code

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    bool isSentByCurrentUser = currentUserId == senderId;

    return Align(
      // Align messages to the left if received, to the right if sent
      alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5),
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: isSentByCurrentUser ? Colors.blue[200] : Colors.grey.shade200,
          borderRadius: isSentByCurrentUser
              ? BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20))
              : BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: isSentByCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              messageContent,
              style: TextStyle(color: isSentByCurrentUser ? Colors.white : Colors.black87),
            ),
            SizedBox(height: 5),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Chat Page Widget
class ChatMessagesTest extends StatefulWidget {
  final String sessionId; // This will act as the senderId.
  final String user;
  final String firstName;
  final String lastName;

  ChatMessagesTest({
    Key? key,
    required this.sessionId,
    required this.user,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}
enum ConnectionStatus { connected, disconnected, connecting }
class _ChatMessagesState extends State<ChatMessagesTest> {
   IO.Socket? socket;
  StreamController<List<ChatMessage>> chatStreamController = StreamController.broadcast();
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();
  ConnectionStatus connectionStatus = ConnectionStatus.connecting;


  @override
  void initState() {
    super.initState();
    _initSocket();
    

  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    socket?.dispose();
    chatStreamController.close();
    super.dispose();
  }

  void _sendMessage() {
  final String newMessageContent = messageController.text.trim();
  if (newMessageContent.isNotEmpty) {
    var message = {
      'content': newMessageContent,
      'senderId': widget.sessionId,
      'receiverId': widget.user,
    };

    socket?.emit('sendMessage', message);
    messageController.clear();

    // Prepare the new message
    ChatMessage newChatMessage = ChatMessage(
      senderId: widget.sessionId,
      receiverId: widget.user,
      timestamp: DateTime.now(),
      messageContent: newMessageContent,
      read: false,
    );

    // Update the messages list and then update the stream
    messages.add(newChatMessage);
    chatStreamController.add(List.from(messages)); // Create a copy of the list
    _scrollToBottom();
    
  }
}



  void _initSocket() {
    // Replace with your actual server URL and socket connection options
    socket = IO.io('https://cf86-2001-4454-415-8a00-20cb-be4f-7389-765c.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
    });
    socket?.connect();

    socket?.onConnect((_) {
      setState(() => connectionStatus = ConnectionStatus.connected);
      print('connected to socket server');
    });
    socket?.onConnectError((data) => print('Connection Error: $data'));
    socket?.onError((data) => print('Error socket: $data'));
    socket?.emit('register', widget.sessionId);


    socket?.on('receiveMessage', (data) => _onReceiveMessage(data));
    _listenForChatHistory();
    _requestChatHistory();
    socket?.onDisconnect((_) {
      setState(() => connectionStatus = ConnectionStatus.disconnected);
      print('disconnected from socket server');
    });

  }

  void _requestChatHistory() {
    socket?.emit('requestChatHistory', {'sessionId': widget.sessionId, 'user': widget.user});
  }

  void _listenForChatHistory() {
    socket?.on('chatHistoryResponse', (data) {
      final chatHistory = (data as List).map((m) => ChatMessage.fromMap(m)).toList();

      // Update the messages list and then update the stream
      messages = chatHistory;
      chatStreamController.add(List.from(messages)); // Create a copy of the list
    });

    socket?.on('chatHistoryError', (data) {
      // Handle the error, possibly show an error message in the UI
    });
  }

  void _onReceiveMessage(dynamic data) {
  print("Received data: $data"); // Debugging print statement
  try {
    ChatMessage newMessage = ChatMessage.fromMap(data);
    messages.add(newMessage);
    chatStreamController.add(List.from(messages)); // Update the stream
    _scrollToBottom();
  } catch (e) {
    print('Error processing received message: $e'); // Error handling
  }
}




  void _scrollToBottom() {
  Future.delayed(Duration(milliseconds: 100), () {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  });
}



  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 2, // Slightly increased elevation for subtle shadow
      automaticallyImplyLeading: false, // Disable the default leading widget
      backgroundColor: Colors.white,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align items across the main axis
        children: <Widget>[
          IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: Colors.blueGrey), // Custom icon color
          ),
          // Displaying user name and online status next to the back button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${widget.firstName} ${widget.lastName}',
                  style: TextStyle(
                    fontSize: 18, // Increased font size
                    fontWeight: FontWeight.bold, // Bold font weight
                    color: Colors.black // Custom text color
                  )
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green, // Online status color
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Online",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic // Italic font style for status
                      )
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Connection status text at the right side
          Text(
            connectionStatus == ConnectionStatus.connected 
                ? "Connected" 
                : (connectionStatus == ConnectionStatus.connecting 
                  ? "Connecting..." 
                  : "Disconnected"),
            style: TextStyle(
              color: connectionStatus == ConnectionStatus.connected 
                  ? Colors.green // Green color for connected status
                  : Colors.red, // Red color for disconnected or connecting status
              fontWeight: FontWeight.w500 // Medium font weight
            ),
          ),
          SizedBox(width: 16), // To ensure some space after the title
        ],
      ),
    
  
      ),


      body: Stack(
        children: <Widget>[
          StreamBuilder<List<ChatMessage>>(
  stream: chatStreamController.stream,
  builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text("No messages yet"));
                
              }
              if (snapshot.hasError) {
          print('StreamBuilder error: ${snapshot.error}'); // Debugging print statement
          // Handle error state
        }

              List<ChatMessage> messages = snapshot.data!;

              return ListView.builder(
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ChatMessageWidgetTest(
                    currentUserId: widget.sessionId,
                    senderId: messages[index].senderId??'Dunno',
                    receiverId: messages[index].receiverId??'Dunno',
                    messageContent: messages[index].messageContent,
                    timestamp: messages[index].timestamp,
                    read: messages[index].read,
                  );
                },
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
 // Pass sessionId as current