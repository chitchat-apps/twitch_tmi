import "package:twitch_tmi/src/message_parser.dart";
import "package:twitch_tmi/twitch_tmi.dart";

enum TmiClientEventType {
  message,
  clearMessage,
  clearChat,
  userState,
  ping,
  connected,
  disconnected,
  error,
  raw,
}

abstract class TmiClientEvent {
  final TmiClientEventType type;

  TmiClientEvent({required this.type});

  factory TmiClientEvent.fromRawIrc(String raw, {String? username}) {
    try {
      final parser = MessageParser(raw);
      final result = parser.parse();

      switch (result.command.type) {
        case CommandType.privMsg:
          return TmiClientMessageEvent(
            tags: result.tags,
            channel: result.command.channel!,
            message: result.parameters?.message ?? "",
            source: result.source!,
            commandType: result.command.type,
            displayName: result.tags?["display-name"],
            isAction: result.parameters?.isAction ?? false,
            isMention: result.parameters?.isMention ?? false,
            isSelf: username?.toLowerCase() == result.source?.nick,
          );
        case CommandType.clearMessage:
          final targetId = result.tags?["target-msg-id"];
          if (targetId == null) {
            return TmiClientRawEvent(raw: parser.raw);
          }

          return TmiClientClearMessageEvent(
            tags: result.tags,
            source: result.source!,
            channel: result.command.channel!,
            message: result.parameters?.message ?? "",
            commandType: result.command.type,
            targetId: targetId,
          );
        case CommandType.clearChat:
          return TmiClientClearChatEvent(
            tags: result.tags,
            source: result.source!,
            channel: result.command.channel!,
            user: result.parameters?.message,
            duration: result.tags?["ban-duration"],
            commandType: result.command.type,
          );
        case CommandType.notice:
          return TmiClientMessageEvent.notice(
            message: result.parameters?.message ?? "",
            channel: result.command.channel!,
            tags: result.tags,
          );
        case CommandType.userState:
          return TmiClientUserStateEvent(
            tags: result.tags,
            source: result.source!,
            channel: result.command.channel!,
            commandType: result.command.type,
            color: result.tags?["color"] ?? "",
            displayName: result.tags?["display-name"] ?? "",
            mod: result.tags?["mod"] == "1",
            subscriber: result.tags?["subscriber"] == "1",
          );
        case CommandType.join:
          return TmiClientMessageEvent.notice(
            message: "Connected",
            channel: result.command.channel!,
          );
        case CommandType.loggedIn:
          return TmiClientConnectedEvent();
        case CommandType.ping:
          return TmiClientPingEvent(host: result.parameters?.message ?? "");
        default:
          return TmiClientRawEvent(raw: parser.raw);
      }
    } catch (e) {
      return TmiClientErrorEvent(message: e.toString());
    }
  }
}

class TmiClientRawEvent extends TmiClientEvent {
  final String raw;

  TmiClientRawEvent({required this.raw}) : super(type: TmiClientEventType.raw);
}

class TmiClientConnectedEvent extends TmiClientEvent {
  TmiClientConnectedEvent() : super(type: TmiClientEventType.connected);
}

class TmiClientDisconnectedEvent extends TmiClientEvent {
  TmiClientDisconnectedEvent() : super(type: TmiClientEventType.disconnected);
}

class TmiClientErrorEvent extends TmiClientEvent {
  String message;

  TmiClientErrorEvent({required this.message})
      : super(type: TmiClientEventType.error);
}

class TmiClientPingEvent extends TmiClientEvent {
  String host;

  TmiClientPingEvent({required this.host})
      : super(type: TmiClientEventType.ping);
}

class TmiClientMessageEvent extends TmiClientEvent {
  Map<String, String>? tags;
  Source source;
  String channel;
  String message;
  CommandType commandType;
  bool isAction;
  String? displayName;
  bool isMention;
  bool isNotice;
  bool isSelf;

  TmiClientMessageEvent({
    this.tags,
    required this.source,
    required this.channel,
    required this.message,
    required this.commandType,
    this.displayName,
    this.isAction = false,
    this.isMention = false,
    this.isNotice = false,
    this.isSelf = false,
  }) : super(type: TmiClientEventType.message);

  factory TmiClientMessageEvent.notice({
    required String message,
    required String channel,
    Map<String, String>? tags,
  }) {
    return TmiClientMessageEvent(
      message: message,
      channel: channel,
      commandType: CommandType.notice,
      source: Source(
        raw: ":tmi.twitch.tv",
        host: "tmi.twitch.tv",
      ),
      tags: tags,
      isNotice: true,
    );
  }
}

class TmiClientClearMessageEvent extends TmiClientEvent {
  Map<String, String>? tags;
  Source source;
  String channel;
  String message;
  CommandType commandType;
  String targetId;

  TmiClientClearMessageEvent({
    required this.source,
    required this.channel,
    required this.message,
    required this.commandType,
    required this.targetId,
    this.tags,
  }) : super(type: TmiClientEventType.clearMessage);
}

class TmiClientClearChatEvent extends TmiClientEvent {
  Map<String, String>? tags;
  Source source;
  String channel;
  CommandType commandType;
  String? user;
  String? duration;

  TmiClientClearChatEvent({
    required this.source,
    required this.channel,
    required this.commandType,
    required this.user,
    required this.duration,
    this.tags,
  }) : super(type: TmiClientEventType.clearChat);
}

class TmiClientUserStateEvent extends TmiClientEvent {
  Map<String, String>? tags;
  Source source;
  String channel;
  CommandType commandType;
  String color;
  String displayName;
  bool mod;
  bool subscriber;

  TmiClientUserStateEvent({
    required this.source,
    required this.channel,
    required this.commandType,
    required this.color,
    required this.displayName,
    this.tags,
    this.mod = false,
    this.subscriber = false,
  }) : super(type: TmiClientEventType.userState);
}
