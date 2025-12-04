import 'package:cloud_firestore/cloud_firestore.dart';

class FeedItem {
  final String id;
  final String type; // 'event' o 'post'
  final Map<String, dynamic> data;
  final Timestamp sortDate; // Usaremos esta para ordenar la lista combinada

  FeedItem({required this.id, required this.type, required this.data, required this.sortDate});
}
