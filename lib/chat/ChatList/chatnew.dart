import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat',
      home: ChatPageNew(),
    );
  }
}

class ChatPageNew extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPageNew> {
  late IO.Socket socket;
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  void initSocket() {
    socket = IO.io('https://ba13-2001-4454-415-8a00-1072-4a9b-35a1-cfc2.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('connected');
      socket.emit('requestChatHistory', {'sessionId': 'yourSessionId', 'user': 'otherUserId'});
    });

    socket.on('chatHistoryResponse', (data) {
      setState(() {
        messages = data;
      });
    });

    socket.on('chatHistoryError', (data) {
      print('Error: ${data['error']}');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
      ),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(messages[index]['message']),
            subtitle: Text('From: ${messages[index]['senderId']}'),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }
}
