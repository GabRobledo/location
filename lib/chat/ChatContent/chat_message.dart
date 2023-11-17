import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../ChatContent/message_list.dart';
import 'package:raamb_app/service/mongo_service.dart';

// Model for chat messages


// Widget for displaying individual chat messages
class ChatMessageWidget extends StatelessWidget {
  final String currentUserId; // Add this line
  final String senderId;
  final String receiverId;
  final String messageContent;
  final DateTime timestamp;
  final bool read;

  const ChatMessageWidget({
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
class ChatMessages extends StatefulWidget {
  final String sessionId; // This will act as the senderId.
  final String user;    
  final String firstName;
  final String lastName;

  ChatMessages({
    Key? key,
    required this.sessionId,
    required this.user,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  _ChatMessagesState createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  IO.Socket? socket;
  List<ChatMessage> messages = [];
  TextEditingController messageController = TextEditingController();
  ScrollController scrollController = ScrollController();

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
    super.dispose();
  }

  void _sendMessage() async {
  final String newMessageContent = messageController.text.trim();
  if (newMessageContent.isNotEmpty) {
    var message = {
      'content': newMessageContent,
      'senderId': widget.sessionId, // Use sessionId as the sender's ID
      'receiverId': widget.user,    // Use user as the receiver's ID
    };

    // Assuming messageType is determined by senderId and receiverId logic
    var messageType = widget.sessionId == message['senderId'] ? 'sender' : 'receiver';

    print("Sending: $message");
    socket?.emit('sendMessage', message);
    print('emit');
    messageController.clear();

    // Add the message to the message list and scroll to the bottom
    setState(() {
      messages.add(ChatMessage(
        senderId: widget.sessionId,
        receiverId: widget.user,
        timestamp: DateTime.now(),
        messageContent: newMessageContent,
        read: false,
        
      ));
      _scrollToBottom();
    });

    // After sending the message through the socket, save it to the database
    // await sendMessageToDb(widget.sessionId, widget.user, newMessageContent);
  }
}

  void _initSocket() {
    // Replace with your actual server URL and socket connection options
    socket = IO.io('https://0dde-2001-4454-415-8a00-410c-ed4c-8569-e71.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      // 'autoConnect': false,
    });
    socket?.connect();

    socket?.onConnect((_) => print('connected to socket server'));
    socket?.onConnectError((data) => print('Connection Error: $data'));
    socket?.onError((data) => print('Error socket: $data'));

    socket?.on('receiveMessage', (data) => _onReceiveMessage(data));
    _listenForChatHistory();
    _requestChatHistory();
    // _fetchChatHistory();
  }

//   void _fetchChatHistory() async {
//   try {
//     final chatHistory = await getChatHistory(widget.sessionId, widget.user);
//     final messages = chatHistory.map((m) => ChatMessage.fromMap(m)).toList();
//     setState(() {
//       this.messages = messages;
//     });
//   } catch (e) {
//     // Handle exceptions, possibly show an error message in the UI
//   }
//   print('receivd');
// }

// Flutter client-side code
// Flutter client-side code
void _requestChatHistory() {
  socket?.emit('requestChatHistory', {'sessionId': widget.sessionId, 'user': widget.user});
}


void _listenForChatHistory() {
  socket?.on('chatHistoryResponse', (data) {
    final chatHistory = (data as List).map((m) => ChatMessage.fromMap(m)).toList();
    setState(() {
      messages = chatHistory;
    });
  });

  socket?.on('chatHistoryError', (data) {
    // Handle the error, possibly show an error message in the UI
  });
}
void _onReceiveMessage(dynamic data) {
  print("Received: $data");
  
  // Parse the incoming message data into a ChatMessage object.
  // Assuming that 'fromMap' is a static method that parses a Map into a ChatMessage.
  ChatMessage newMessage = ChatMessage.fromMap(data);

  // Update the state with the new message.
  setState(() {
    messages.add(newMessage);
  });

  // If you need to ensure that the new message is visible, schedule a scroll after the UI updates.
  // However, this should probably be outside the setState to avoid unnecessary calls.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scrollController.hasClients) {
      _scrollToBottom(); // This now will work correctly with the updated list.
    }
  });
}



//   void _onReceiveMessage(dynamic data) {
//   print("Received: $data");
//   var messageType = data['senderId'] == widget.sessionId ? 'sender' : 'receiver';

//   // Create a new ChatMessage with all required fields.
//   ChatMessage newMessage = ChatMessage(
//      // Assuming '_id' comes from your data
//     senderId: data['senderId'],
//     receiverId: data['receiverId'],
//     messageContent: data['content'],
//     timestamp: DateTime.parse(data['timestamp']), // Converting timestamp string to DateTime
//     read: data['read'], // The 'read' status from your data
//     // 'sender' or 'receiver' determined by comparison
//   );

//   setState(() {
//     messages.add(newMessage);
//     _scrollToBottom(); // Scroll to the bottom whenever a new message is received
//   });
// }


  void _scrollToBottom() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
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
                // CircleAvatar(
                //   backgroundImage: NetworkImage("https://randomuser.me/api/portraits/men/5.jpg"),
                //   maxRadius: 20,
                // ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('${widget.firstName} ${widget.lastName}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
    currentUserId: widget.sessionId, // Pass sessionId as currentUserId here
    senderId: messages[index].senderId,
    receiverId: messages[index].receiverId,
    messageContent: messages[index].messageContent,
    timestamp: messages[index].timestamp,
    read: messages[index].read, // Assuming you have a read status
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
