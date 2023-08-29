import "package:flutter_test/flutter_test.dart";
import "package:twitch_tmi/src/message_parser.dart";
import "package:twitch_tmi/twitch_tmi.dart";

void main() {
  test("parse PING message", () {
    const rawPING = "PING :tmi.twitch.tv";

    final parser = MessageParser(rawPING);
    final result = parser.parse();

    expect(result.tags, isNull);
    expect(result.source, isNull);

    final command = Command(
      raw: "PING",
      type: CommandType.ping,
    );
    expect(
      result.command.raw,
      command.raw,
    );
    expect(
      result.command.type,
      command.type,
    );
    expect(
      result.command.channel,
      isNull,
    );

    expect(result.parameters?.message, "tmi.twitch.tv");
  });

  test("parse a PRIVMSG message", () {
    const rawPRIVMSG =
        "@badges=staff/1,broadcaster/1,turbo/1;color=#FF0000;display-name=PetsgomOO;emote-only=1;emotes=33:0-7;flags=0-7:A.6/P.6,25-36:A.1/I.2;id=c285c9ed-8b1b-4702-ae1c-c64d76cc74ef;mod=0;room-id=81046256;subscriber=0;turbo=0;tmi-sent-ts=1550868292494;user-id=81046256;user-type=staff :petsgomoo!petsgomoo@petsgomoo.tmi.twitch.tv PRIVMSG #petsgomoo :DansGame";

    final parser = MessageParser(rawPRIVMSG);
    final result = parser.parse();

    expect(result.tags, <String, String>{
      "badges": "staff/1,broadcaster/1,turbo/1",
      "color": "#FF0000",
      "display-name": "PetsgomOO",
      "emote-only": "1",
      "emotes": "33:0-7",
      "flags": "0-7:A.6/P.6,25-36:A.1/I.2",
      "id": "c285c9ed-8b1b-4702-ae1c-c64d76cc74ef",
      "mod": "0",
      "room-id": "81046256",
      "subscriber": "0",
      "tmi-sent-ts": "1550868292494",
      "turbo": "0",
      "user-id": "81046256",
      "user-type": "staff",
    });

    final source = Source(
      raw: "petsgomoo!petsgomoo@petsgomoo.tmi.twitch.tv",
      nick: "petsgomoo",
      host: "petsgomoo@petsgomoo.tmi.twitch.tv",
    );
    expect(
      result.source?.raw,
      source.raw,
    );
    expect(
      result.source?.nick,
      source.nick,
    );
    expect(
      result.source?.host,
      source.host,
    );

    final command = Command(
      raw: "PRIVMSG #petsgomoo",
      type: CommandType.privMsg,
      channel: "petsgomoo",
    );
    expect(
      result.command.raw,
      command.raw,
    );
    expect(
      result.command.type,
      command.type,
    );
    expect(
      result.command.channel,
      command.channel,
    );

    expect(result.parameters?.message, "DansGame");
  });

  test("parse a PRIVMSG message without tags", () {
    const rawPRIVMSG =
        ":lovingt3s!lovingt3s@lovingt3s.tmi.twitch.tv PRIVMSG #lovingt3s :!dilly";

    final parser = MessageParser(rawPRIVMSG);
    final result = parser.parse();

    expect(result.tags, isNull);

    final source = Source(
      raw: "lovingt3s!lovingt3s@lovingt3s.tmi.twitch.tv",
      nick: "lovingt3s",
      host: "lovingt3s@lovingt3s.tmi.twitch.tv",
    );
    expect(
      result.source?.raw,
      source.raw,
    );
    expect(
      result.source?.nick,
      source.nick,
    );
    expect(
      result.source?.host,
      source.host,
    );

    final command = Command(
      raw: "PRIVMSG #lovingt3s",
      type: CommandType.privMsg,
      channel: "lovingt3s",
    );
    expect(
      result.command.raw,
      command.raw,
    );
    expect(
      result.command.type,
      command.type,
    );
    expect(
      result.command.channel,
      command.channel,
    );

    expect(result.parameters?.message, "!dilly");
  });

  test("parse a PRIVMSG that is an action /me", () {
    const rawPRIVMSG =
        ":sebbdev!sebbdev@sebbdev.tmi.twitch.tv PRIVMSG #sebbdev :ACTION test";

    final parser = MessageParser(rawPRIVMSG);
    final result = parser.parse();

    expect(result.parameters?.isAction, isTrue);
  });

  test("parse a PRIVMSG that is a mention (both with and without the @)", () {
    const username = "sebbdev";
    const rawPRIVMSG1 =
        ":sebbdev!sebbdev@sebbdev.tmi.twitch.tv PRIVMSG #sebbdev :@$username hello";

    // without the @
    const rawPRIVMSG2 =
        ":sebbdev!sebbdev@sebbdev.tmi.twitch.tv PRIVMSG #sebbdev :$username hello";

    final parser = MessageParser(rawPRIVMSG1, username: username);
    final result = parser.parse();

    expect(result.parameters?.isMention, isTrue);

    final parser2 = MessageParser(rawPRIVMSG2, username: username);
    final result2 = parser2.parse();

    expect(result2.parameters?.isMention, isTrue);
  });
}
