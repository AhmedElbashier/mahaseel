class Conversation {
  final int id;
  final int? listingId;
  final Message? lastMessage;
  final int unreadCount;
  Conversation({required this.id, this.listingId, this.lastMessage, required this.unreadCount});
  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
    id: j['id'],
    listingId: j['listing_id'],
    lastMessage: j['last_message'] != null ? Message.fromJson(j['last_message']) : null,
    unreadCount: j['unread_count'] ?? 0,
  );
}

class Message {
  final int id;
  final int conversationId;
  final int senderId;
  final String body;
  final DateTime createdAt;
  Message({required this.id, required this.conversationId, required this.senderId, required this.body, required this.createdAt});
  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id: j['id'],
    conversationId: j['conversation_id'],
    senderId: j['sender_id'],
    body: j['body'],
    createdAt: DateTime.parse(j['created_at']),
  );
}
