import 'package:flutter/material.dart';
import '../chat/ChatList/chat_list.dart';

class ChatUsers {
  String name;
  String secondaryText;
  String imageURL;
  String time;
  String messageText;

  ChatUsers({
    required this.name,
    required this.secondaryText,
    required this.imageURL,
    required this.time,
    required this.messageText,
  });
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<ChatUsers> chatUsers = [
    ChatUsers(
      name: "Jane Russel",
      secondaryText: "Awesome Setup",
      imageURL: "images/userImage1.jpeg",
      time: "Now",
      messageText: "Hello, how are you?",
    ),
    ChatUsers(
      name: "Glady's Murphy",
      secondaryText: "That's Great",
      imageURL: "images/userImage2.jpeg",
      time: "Yesterday",
      messageText: "Hi there!",
    ),
    // Add similar entries for other users
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SafeArea(
              child: Padding(
                padding: EdgeInsets.only(left: 16, right: 16, top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Conversations",
                      style:
                          TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding:
                          EdgeInsets.only(left: 8, right: 8, top: 2, bottom: 2),
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: Colors.pink[0],
                      ),
                      child: Row(
                        children: <Widget>[
                          // Icon(
                          //   Icons.add,
                          //   color: Colors.pink,
                          //   size: 20,
                          // ),
                          // SizedBox(
                          //   width: 2,
                          // ),
                          // Text(
                          //   "Add New",
                          //   style: TextStyle(
                          //       fontSize: 14, fontWeight: FontWeight.bold),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: 16, left: 16, right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search...",
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.all(8),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: Colors.grey.shade100,
                      )),
                ),
              ),
            ),
            ListView.builder(
              itemCount: chatUsers.length,
              shrinkWrap: true,
              padding: EdgeInsets.only(top: 16),
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ChatList(
                  name: chatUsers[index].name,
                  messageText: chatUsers[index].messageText,
                  imageUrl: chatUsers[index].imageURL,
                  time: chatUsers[index].time,
                  isMessageRead: (index == 0 || index == 3) ? true : false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
