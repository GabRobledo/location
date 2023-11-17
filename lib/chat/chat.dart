import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-time Messages',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MessageListScreen(),
    );
  }
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.read,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['_id'],
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      read: map['read'],
    );
  }
}

class MessageListScreen extends StatefulWidget {
  @override
  _MessageListScreenState createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  List<Message> _messages = [];
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('https://0dde-2001-4454-415-8a00-410c-ed4c-8569-e71.ngrok-free.app/', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('connect');
      socket.emit('getMessages', {'userId': 'your_user_id'});
    });

    socket.on('message', (data) {
      setState(() {
        _messages.insert(0, Message.fromMap(json.decode(data)));
      });
    });

    socket.onDisconnect((_) => print('disconnect'));
    socket.onError((data) => print(data));
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Messages'),
      ),
      body: ListView.builder(
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          return ListTile(
            leading: CircleAvatar(
              child: Text(message.senderId.substring(0, 1)),
            ),
            title: Text(message.content),
            subtitle: Text(message.timestamp.toLocal().toString()),
            trailing: Icon(
              message.read ? Icons.visibility : Icons.visibility_off,
              color: message.read ? Colors.green : Colors.red,
            ),
          );
        },
      ),
    );
  }
}
