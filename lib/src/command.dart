import "package:twitch_tmi/src/command_type.dart";

class Command {
  final String raw;
  final CommandType type;
  final String? channel;

  Command({required this.raw, required this.type, this.channel});
}
