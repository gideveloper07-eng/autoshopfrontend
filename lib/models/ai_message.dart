import 'package:flutter/material.dart';

enum MessageSender {
  user,
  ai,
}

enum MessageStatus {
  sending,
  sent,
  failed,
}

class AIMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime time;
  final MessageStatus status;
  final bool isMarkdown;

  const AIMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.time,
    this.status = MessageStatus.sent,
    this.isMarkdown = false,
  });

  bool get isUser => sender == MessageSender.user;

  bool get isAI => sender == MessageSender.ai;

  AIMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? time,
    MessageStatus? status,
    bool? isMarkdown,
  }) {
    return AIMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      time: time ?? this.time,
      status: status ?? this.status,
      isMarkdown: isMarkdown ?? this.isMarkdown,
    );
  }

  factory AIMessage.user(String text) {
    return AIMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.user,
      time: DateTime.now(),
    );
  }

  factory AIMessage.ai(String text) {
    return AIMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      sender: MessageSender.ai,
      time: DateTime.now(),
      isMarkdown: true,
    );
  }

  factory AIMessage.typing() {
    return AIMessage(
      id: "typing",
      text: "",
      sender: MessageSender.ai,
      time: DateTime.now(),
      status: MessageStatus.sending,
    );
  }
}