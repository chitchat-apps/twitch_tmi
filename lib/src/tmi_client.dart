import "dart:async";

import "package:logger/logger.dart";
import "package:twitch_tmi/src/tmi_client_events.dart";
import "package:web_socket_channel/web_socket_channel.dart";

class TmiClient {
  static final Uri webSocketUri = Uri.parse("wss://irc-ws.chat.twitch.tv:443");

  late final Logger _logger;
  final bool logs;
  final Level logLevel;
  final bool autoPong;
  final _streamController = StreamController<TmiClientEvent>.broadcast();

  List<String> channels;
  String? token;
  String? username;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _connected = false;

  bool get connected => _connected;

  TmiClient({
    this.token,
    this.username,
    this.channels = const [],
    this.logs = true,
    this.logLevel = Level.info,
    this.autoPong = true,
  }) {
    _logger = _createLogger();
    _logger.d("TmiClient created");
  }

  StreamSubscription<TmiClientEvent> listen(
      void Function(TmiClientEvent event) listener) {
    return _streamController.stream.listen(listener);
  }

  void connect() {
    _channel?.sink.close();

    _channel = WebSocketChannel.connect(webSocketUri);
    _subscription = _channel?.stream.listen((data) {
      final strData = data.toString();
      _logger.d(
          "Message received (${DateTime.now().toIso8601String()}):\r\n${strData.trimRight()}");
      final messages = strData.split("\r\n");
      for (final message in messages) {
        if (message.isEmpty) {
          continue;
        }

        final event = TmiClientEvent.fromRawIrc(message, username: username);

        // additional logic before adding event to stream
        if (event is TmiClientConnectedEvent) {
          _connected = true;
        }
        if (event is TmiClientDisconnectedEvent) {
          _connected = false;
        }
        if (autoPong && event is TmiClientPingEvent) {
          _logger.d("Received PING, AutoPong is true; sending PONG");
          pong();
        }
        if (logs && event is TmiClientErrorEvent) {
          _logger.e(event.message);
        }

        _streamController.add(event);
      }
    }, onDone: () {
      disconnect();
    }, onError: (error) {
      _logger.e(error);
      _streamController.add(TmiClientErrorEvent(message: error.toString()));
    }, cancelOnError: false);

    _sendInitCommands();
  }

  void disconnect() {
    _channel?.sink.close();
    _subscription?.cancel();
    _connected = false;
    _channel = null;
    _subscription = null;
    _streamController.add(TmiClientDisconnectedEvent());
  }

  void send({required String channel, required String message}) {
    _channel?.sink.add("PRIVMSG #$channel :$message");
  }

  void reply({
    required String channel,
    required String messageId,
    required String message,
  }) {
    _channel?.sink.add(
      "@reply-parent-msg-id=$messageId PRIVMSG #$channel :$message",
    );
  }

  void join(String channel) {
    _logger.d("Joining channel $channel");
    channel = channel.toLowerCase();
    final existingIndex = channels.indexWhere(
      (element) => element.toLowerCase() == channel,
    );
    if (existingIndex != -1) {
      _logger.d("Channel $channel already joined");
    } else {
      channels.add(channel);
    }

    _channel?.sink.add("JOIN #$channel");
  }

  void part(String channel) {
    _logger.d("Parting channel $channel");
    channel = channel.toLowerCase();
    final existingIndex = channels.indexWhere(
      (element) => element.toLowerCase() == channel,
    );
    if (existingIndex == -1) {
      _logger.d("Channel $channel not found");
    } else {
      channels.removeAt(existingIndex);
    }

    _channel?.sink.add("PART #$channel");
  }

  void pong() {
    _channel?.sink.add("PONG :tmi.twitch.tv");
  }

  void _sendInitCommands() {
    final usr = username ?? "justinfan1243";
    final commands = [
      // Tags and commands
      "CAP REQ :twitch.tv/tags twitch.tv/commands",

      // Authentication
      "PASS oauth:$token",

      // Nickname
      "NICK $usr",
    ];

    for (final channel in channels) {
      commands.add("JOIN #$channel");
    }

    for (final command in commands) {
      _channel?.sink.add("$command\r\n");
    }
  }

  Logger _createLogger() {
    return Logger(
      level: logs ? logLevel : Level.off,
      printer: PrettyPrinter(
        methodCount: 0,
        errorMethodCount: 8,
        lineLength: 80,
        colors: true,
        printEmojis: true,
        printTime: false,
      ),
    );
  }

  void dispose() {
    _channel?.sink.close();
    _subscription?.cancel();
    _connected = false;
    _channel = null;
    _subscription = null;

    _streamController.close();

    _logger.d("TmiClient disposed");
  }
}
