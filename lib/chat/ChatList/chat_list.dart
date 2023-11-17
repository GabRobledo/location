import 'package:flutter/material.dart';
import '../ChatContent/chat_message.dart';

class ChatList extends StatefulWidget {
  final String name;
  final String messageText;
  final String imageUrl;
  final String time;
  final bool isMessageRead;

  ChatList({
    required this.name,
    required this.messageText,
    required this.imageUrl,
    required this.time,
    required this.isMessageRead,
  });

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Add navigation to chat details
      },
      child: Container(
        padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundImage: NetworkImage(widget.imageUrl),
              maxRadius: 30,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.name,
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 6),
                  Text(
                    widget.messageText,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: widget.isMessageRead
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              widget.time,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.isMessageRead ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
