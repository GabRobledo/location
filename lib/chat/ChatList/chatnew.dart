import 'package:flutter/material.dart';
import 'package:raamb_app/chat/chattest.dart';
import 'package:intl/intl.dart';
import 'package:raamb_app/service/mongo_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;


// RecentMessage model
class RecentMessage {
  final String senderId;
  final String receiverId;
  String lastMessage;
  DateTime timestamp;
  String? senderFirstName;
  String? senderLastName;
  String? receiverFirstName;
  String? receiverLastName;

  RecentMessage({
    required this.senderId,
    required this.receiverId,
    required this.lastMessage,
    required this.timestamp,
    this.senderFirstName,
    this.senderLastName,
    this.receiverFirstName,
    this.receiverLastName,
  });

  factory RecentMessage.fromMap(Map<String, dynamic> data) {
    DateTime parsedTimestamp;
    if (data['timestamp'] is String) {
      parsedTimestamp = DateTime.parse(data['timestamp']).toLocal(); // Convert to local time zone
    } else if (data['timestamp'] is DateTime) {
      parsedTimestamp = data['timestamp'].toLocal(); // Convert to local time zone
    } else {
      parsedTimestamp = DateTime.now(); // Default value or handle appropriately
    }

    // Convert to Philippine Time Zone (PHT)
    tz.initializeTimeZones();
    var location = tz.getLocation('Asia/Manila');
    var phtTimestamp = tz.TZDateTime.from(parsedTimestamp, location);

    return RecentMessage(
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      lastMessage: data['content'],
      timestamp: phtTimestamp,
      // ... [Add other fields if necessary]
    );
  }
}


// RecentMessagesWidget
class RecentMessagesWidget extends StatefulWidget {
  final String sessionId;

  const RecentMessagesWidget({Key? key, required this.sessionId}) : super(key: key);

  @override
  _RecentMessagesWidgetState createState() => _RecentMessagesWidgetState();
}

class _RecentMessagesWidgetState extends State<RecentMessagesWidget> {
  List<RecentMessage> recentMessages = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchRecentMessages();
  }

  void fetchRecentMessages() async {
  try {
    List<Map<String, dynamic>> messagesData = await getMessagesForSession(widget.sessionId);
    Map<String, RecentMessage> conversations = {};

    for (var data in messagesData) {
      String senderId = data['senderId'];
      String receiverId = data['receiverId'];

      var senderDetails = await getUserData(senderId);
      var receiverDetails = await getUserData(receiverId);

      String conversationId = getConversationId(widget.sessionId, senderId == widget.sessionId ? receiverId : senderId);

      String lastMessage = data['content']; // Assuming 'content' holds the last message text

      // Handle timestamp
      DateTime timestamp;
      if (data['timestamp'] is String) {
        timestamp = DateTime.parse(data['timestamp']);
      } else if (data['timestamp'] is DateTime) {
        timestamp = data['timestamp'];
      } else {
        timestamp = DateTime.now(); // Default value or handle appropriately
      }

      // Convert to Philippine Time Zone (PHT), if needed
      tz.initializeTimeZones();
      var location = tz.getLocation('Asia/Manila');
      var phtTimestamp = tz.TZDateTime.from(timestamp, location);

      // Check if the conversation already exists
      if (conversations.containsKey(conversationId)) {
        // Update the last message of the existing conversation
        conversations[conversationId]!.lastMessage = lastMessage;
        conversations[conversationId]!.timestamp = phtTimestamp;
      } else {
        // Create and add a new conversation
        conversations[conversationId] = RecentMessage(
          senderId: senderId,
          receiverId: receiverId,
          lastMessage: lastMessage,
          timestamp: phtTimestamp,
          senderFirstName: senderDetails?['firstName'] ?? 'Unknown',
          senderLastName: senderDetails?['lastName'] ?? 'User',
          receiverFirstName: receiverDetails?['firstName'] ?? 'Unknown',
          receiverLastName: receiverDetails?['lastName'] ?? 'User',
        );
      }
    }

    setState(() {
      recentMessages = conversations.values.toList();
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      errorMessage = "Error fetching recent messages: $e";
      isLoading = false;
    });
  }
}



String getConversationId(String id1, String id2) {
  // Sort the IDs to ensure the identifier is consistent regardless of who sends the message
  var sortedIds = [id1, id2]..sort();
  return '${sortedIds[0]}_${sortedIds[1]}';
}




  @override
Widget build(BuildContext context) {
  ThemeData theme = Theme.of(context);

  if (isLoading) {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
      ),
    );
  }

  if (errorMessage != null) {
    return Center(
      child: Text(
        errorMessage!,
        style: TextStyle(color: theme.errorColor),
      ),
    );
  }

  return ListView.builder(
    itemCount: recentMessages.length,
    itemBuilder: (context, index) {
      final message = recentMessages[index];
      bool isCurrentUserSender = message.senderId == widget.sessionId;
      String userId = isCurrentUserSender ? message.receiverId : message.senderId;
      String userName = isCurrentUserSender 
          ? "${message.receiverFirstName} ${message.receiverLastName}" 
          : "${message.senderFirstName} ${message.senderLastName}";

      return Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage("https://example.com/user/profile/$userId.jpg"),
            backgroundColor: Colors.grey.shade300,
            onBackgroundImageError: (exception, stackTrace) {
              // Handle image loading error
            },
            child: Text(userName[0].toUpperCase()), // Initial letter as placeholder
          ),
          title: Text(userName, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(
  '${isCurrentUserSender ? "You: " : ""}${message.lastMessage}\n'
  '${DateFormat('MMM dd, yyyy - hh:mm a').format(message.timestamp)}',
  style: TextStyle(color: Colors.grey[600]),
),



          trailing: Icon(
            Icons.check, // Example icon, change as needed
            color: theme.primaryColor,
          ),
          isThreeLine: true,
          onTap: () => navigateToChat(context, message, userId),
        ),
      );
    },
  );
}



  void navigateToChat(BuildContext context, RecentMessage message, String userId) {
  bool isCurrentUserSender = message.senderId == widget.sessionId;

  // Determine the first name and last name based on whether the user is the sender or receiver
  String firstName = isCurrentUserSender ? message.receiverFirstName ?? 'Unknown' : message.senderFirstName ?? 'Unknown';
  String lastName = isCurrentUserSender ? message.receiverLastName ?? 'Unknown' : message.senderLastName ?? 'Unknown';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChatMessagesTest(
        sessionId: widget.sessionId,
        user: userId,
        firstName: firstName, // Actual first name
        lastName: lastName, // Actual last name
      ),
    ),
  );
}

}
class RecentMessagesScreen extends StatelessWidget {
  final String sessionId;

  RecentMessagesScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple, // Changed to a violet-like color
        title: Text(
          "Recent Messages",
          style: TextStyle(
            color: Colors.white, // Ensuring the title is clearly visible
            fontWeight: FontWeight.bold, // Making the title bold
          ),
        ),
        elevation: 0, // Optional: Setting elevation to 0 for a flat design
      ),
      body: RecentMessagesWidget(sessionId: sessionId),
    );
  }
}
