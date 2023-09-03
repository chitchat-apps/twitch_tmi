import "package:twitch_tmi/src/command.dart";
import "package:twitch_tmi/src/command_type.dart";
import "package:twitch_tmi/src/parameters.dart";
import "package:twitch_tmi/src/source.dart";

class MessageParser {
  final String raw;
  final String? _username;

  var _position = 0;

  String get _current => raw[_position];

  Map<String, String>? _tags;
  Source? _source;
  late Command _command;
  Parameters? _parameters;

  MessageParser(String raw, {String? username})
      : raw = raw.trim(),
        _username = username;

  ParseResult parse() {
    // if IRC message starts with @, it contains tags
    if (_current == "@") {
      _parseTags();
    }

    // next we check if the IRC message contains a source (nick and host)
    if (_current == ":") {
      _parseSource();
    }

    _parseCommandAndParameters();

    return ParseResult(
      tags: _tags,
      source: _source,
      command: _command,
      parameters: _parameters,
    );
  }

  void _advance({int count = 1}) {
    _position += count;
  }

  // example: PRIVMSG #petsgomoo :DansGame
  void _parseCommandAndParameters() {
    var endIndex = raw.indexOf(":", _position);
    if (endIndex == -1) {
      endIndex = raw.length;
    }

    final rawCommand = raw.substring(_position, endIndex).trim();

    if (endIndex != raw.length) {
      _advance(count: endIndex - _position + 1);
      _parseParameters();
    }

    _parseCommand(rawCommand);
  }

  void _parseParameters() {
    final rawParameters = raw.substring(_position);
    String? message;
    bool isAction = false;
    bool isMention = false;

    if (rawParameters.startsWith("\x01") && rawParameters.endsWith("\x01")) {
      message = rawParameters.substring(8, rawParameters.length - 1);
      isAction = true;
    } else {
      message = rawParameters;
    }

    if (_username != null) {
      isMention = message.toLowerCase().contains(_username!.toLowerCase());
    }

    _parameters = Parameters(
      raw: rawParameters,
      message: message,
      isAction: isAction,
      isMention: isMention,
    );
  }

  void _parseCommand(String rawCommand) {
    final parts = rawCommand.split(" ");
    switch (parts.firstOrNull) {
      case IrcCommands.privMsg:
        _command = Command(
          raw: rawCommand,
          type: CommandType.privMsg,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.join:
        _command = Command(
          raw: rawCommand,
          type: CommandType.join,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.part:
        _command = Command(
          raw: rawCommand,
          type: CommandType.part,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.notice:
        _command = Command(
          raw: rawCommand,
          type: CommandType.notice,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.clearMessage:
        _command = Command(
          raw: rawCommand,
          type: CommandType.clearMessage,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.clearChat:
        _command = Command(
          raw: rawCommand,
          type: CommandType.clearChat,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.hostTarget:
        _command = Command(
          raw: rawCommand,
          type: CommandType.hostTarget,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.ping:
        _command = Command(
          raw: rawCommand,
          type: CommandType.ping,
        );
        break;
      case IrcCommands.unsupported:
        _command = Command(
          raw: rawCommand,
          type: CommandType.unknown,
        );
        break;
      case IrcCommands.loggedIn:
        _command = Command(
          raw: rawCommand,
          type: CommandType.loggedIn,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.globalUserState:
        _command = Command(
          raw: rawCommand,
          type: CommandType.globalUserState,
        );
        break;
      case IrcCommands.userState:
        _command = Command(
          raw: rawCommand,
          type: CommandType.userState,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.roomState:
        _command = Command(
          raw: rawCommand,
          type: CommandType.roomState,
          channel: parts.elementAtOrNull(1)?.substring(1),
        );
        break;
      case IrcCommands.reconnect:
        _command = Command(
          raw: rawCommand,
          type: CommandType.reconnect,
        );
        break;
      case IrcCommands.cap:
        _command = Command(
          raw: rawCommand,
          type: CommandType.cap,
        );
        break;
      case IrcCommands.none:
      default:
        _command = Command(
          raw: rawCommand,
          type: CommandType.unknown,
        );
        break;
    }
  }

  // example: :petsgomoo!petsgomoo@petsgomoo.tmi.twitch.tv
  void _parseSource() {
    _advance(); // skip :

    final endIndex = raw.indexOf(" ", _position);
    final rawSource = raw.substring(_position, endIndex);
    final sourceParts = rawSource.split("!");

    _source = Source(
      raw: rawSource,
      nick: sourceParts.firstOrNull,
      host: sourceParts.lastOrNull ?? sourceParts.firstOrNull,
    );

    _advance(count: endIndex - _position + 1); // skip source and space
  }

  // example: @badges=staff/1,broadcaster/1,turbo/1;color=#FF0000;display-name=PetsgomOO;emote-only=1;emotes=33:0-7;flags=0-7:A.6/P.6,25-36:A.1/I.2;id=c285c9ed-8b1b-4702-ae1c-c64d76cc74ef;mod=0;room-id=81046256;subscriber=0;turbo=0;tmi-sent-ts=1550868292494;user-id=81046256;user-type=staff
  void _parseTags() {
    _advance(); // skip @
    final tags = <String, String>{};
    final endIndex = raw.indexOf(" ", _position);
    final parsedTags = raw.substring(_position, endIndex).split(";");

    for (final tag in parsedTags) {
      final parts = tag.split("=");
      final key = parts.firstOrNull;
      final value = parts.length > 1 ? parts.last : null;

      if (key != null && value != null && value.isNotEmpty) {
        tags[key] = value;
      }
    }

    if (tags.isNotEmpty) {
      _tags = tags;
    }
    _advance(count: endIndex - _position + 1); // skip tags and space
  }
}

abstract class IrcCommands {
  static const String join = "JOIN";
  static const String part = "PART";
  static const String notice = "NOTICE";
  static const String clearMessage = "CLEARMSG";
  static const String clearChat = "CLEARCHAT";
  static const String hostTarget = "HOSTTARGET";
  static const String privMsg = "PRIVMSG";
  static const String ping = "PING";
  static const String cap = "CAP";
  static const String globalUserState = "GLOBALUSERSTATE";
  static const String userState = "USERSTATE";
  static const String roomState = "ROOMSTATE";
  static const String reconnect = "RECONNECT";
  static const String unsupported = "421";
  static const String loggedIn = "001";
  static const String none = "NONE";
}

class ParseResult {
  final Map<String, String>? tags;
  final Source? source;
  final Command command;
  final Parameters? parameters;

  ParseResult({
    this.tags,
    this.source,
    required this.command,
    this.parameters,
  });
}

// @badges=staff/1,broadcaster/1,turbo/1;color=#FF0000;display-name=PetsgomOO;emote-only=1;emotes=33:0-7;flags=0-7:A.6/P.6,25-36:A.1/I.2;id=c285c9ed-8b1b-4702-ae1c-c64d76cc74ef;mod=0;room-id=81046256;subscriber=0;turbo=0;tmi-sent-ts=1550868292494;user-id=81046256;user-type=staff :petsgomoo!petsgomoo@petsgomoo.tmi.twitch.tv PRIVMSG #petsgomoo :DansGame
