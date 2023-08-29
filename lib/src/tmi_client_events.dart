import "package:twitch_tmi/src/command_type.dart";
import "package:twitch_tmi/src/message_parser.dart";
import "package:twitch_tmi/twitch_tmi.dart";

enum TmiClientEventType {
  message,
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
            isAction: result.parameters?.isAction ?? false,
            isMention: result.parameters?.isMention ?? false,
            isSelf: username?.toLowerCase() == result.source?.nick,
          );
        case CommandType.notice:
          return TmiClientMessageEvent.notice(
            message: result.parameters?.message ?? "",
            channel: result.command.channel!,
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
  final String message;

  TmiClientErrorEvent({required this.message})
      : super(type: TmiClientEventType.error);
}

class TmiClientPingEvent extends TmiClientEvent {
  final String host;

  TmiClientPingEvent({required this.host})
      : super(type: TmiClientEventType.ping);
}

class TmiClientMessageEvent extends TmiClientEvent {
  final Map<String, String>? tags;
  final Source source;
  final String channel;
  final String message;
  final CommandType commandType;
  final bool isAction;
  final bool isMention;
  final bool isNotice;
  final bool isSelf;

  TmiClientMessageEvent({
    this.tags,
    required this.source,
    required this.channel,
    required this.message,
    required this.commandType,
    this.isAction = false,
    this.isMention = false,
    this.isNotice = false,
    this.isSelf = false,
  }) : super(type: TmiClientEventType.message);

  factory TmiClientMessageEvent.notice({
    required String message,
    required String channel,
  }) {
    return TmiClientMessageEvent(
      message: message,
      channel: channel,
      commandType: CommandType.notice,
      source: Source(
        raw: ":tmi.twitch.tv",
        host: "tmi.twitch.tv",
      ),
      isNotice: true,
    );
  }
}
