class ChatMessage {
  // Make fields nullable if the data can be null
  final String? senderId;
  final String? receiverId;
  final String messageContent;
  final DateTime timestamp;
  final bool read;

  ChatMessage({
    // Fields can be nullable
    this.senderId,
    this.receiverId,
    required this.messageContent,
    required this.timestamp,
    required this.read,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    // Provide default values or handle null with checks
    return ChatMessage(
      senderId: map['senderId'] as String?,
      receiverId: map['receiverId'] as String?,
      // Assuming 'content' is never null, add a check if necessary
      messageContent: map['content'] as String,
      // Use a default timestamp if the map value is null or not a valid timestamp
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
      // Provide a default 'read' status if null
      read: map['read'] as bool? ?? false,
    );
  }
  
  // ... other code
}
