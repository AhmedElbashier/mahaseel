import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chats.dart';
class ChatRepo {
  final Dio _dio;
  ChatRepo(this._dio);

  Future<List<Conversation>> listConversations(String scope) async {
    final res = await _dio.get('/chat/conversations', queryParameters: {'scope': scope});
    return (res.data as List).map((e) => Conversation.fromJson(e)).toList();
  }

  Future<List<Message>> listMessages(int cid, {int limit = 30, int? beforeId}) async {
    final res = await _dio.get('/chat/conversations/$cid/messages', queryParameters: {'limit': limit, if (beforeId != null) 'before_id': beforeId});
    return (res.data as List).map((e) => Message.fromJson(e)).toList();
  }

  Future<Message> sendMessage(int cid, String body) async {
    // ✅ use the new path that matches the backend
    final res = await _dio.post(
      '/chat/conversations/$cid/messages',
      data: {'body': body},
    );
    return Message.fromJson(res.data);
  }



  // NEW: create or get existing conversation tied to this listing & seller
  Future<Conversation> createOrGetConversation({
    required int otherUserId, // seller id
    required int listingId,   // crop id
    required String role,     // "buyer" or "seller"
  }) async {
    try {
      final res = await _dio.post(
        '/chat/conversations',
        data: {
          'other_user_id': otherUserId,
          'listing_id': listingId,
          'role': role,
        },
      );
      // Backend returns a ConversationOut
      final data = res.data;
      if (data is Map<String, dynamic>) {
        return Conversation.fromJson(data);
      }
      // Defensive: try to coerce
      return Conversation.fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      final code = e.response?.statusCode ?? 0;
      final body = e.response?.data;
      final detail = (body is Map && body['detail'] is String) ? body['detail'] as String : null;

      if (code == 400) {
        // Our backend sends 400 for self-chat
        if ((detail ?? '').toLowerCase().contains('yourself')) {
          throw Exception('You cannot start a conversation with your own listing.');
        }
        throw Exception(detail ?? 'Bad request when creating conversation.');
      }
      if (code == 404) {
        throw Exception('Chat endpoint not found. Check API prefix (e.g. /api/chat/conversations).');
      }
      if (code == 401 || code == 403) {
        throw Exception('Please sign in again to start a conversation.');
      }

      throw Exception('Error $code: ${detail ?? e.message ?? 'Failed to create/open conversation.'}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }


  WebSocketChannel connectWS(String wsBase, int cid, String token) {
    final uri = Uri.parse('$wsBase/ws/chat/$cid?token=$token');
    return WebSocketChannel.connect(uri);
  }
}
