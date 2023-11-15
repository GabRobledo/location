class ChatMessage {
  
  final String senderId;
  final String receiverId;
  final String messageContent;
  
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    
    required this.senderId,
    required this.receiverId,
    required this.messageContent,
    required this.timestamp,
    required this.read,
    
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      
      senderId: map['senderId'],
      receiverId: map['receiverId'],
      messageContent: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      read: map['read'],
    );
  }
  
  // ... other code
}
