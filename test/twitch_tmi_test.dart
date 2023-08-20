import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter_test/flutter_test.dart";

import "package:twitch_tmi/twitch_tmi.dart";

void main() {
  test("connect to chat", () async {
    await dotenv.load();
    final token = dotenv.env["ACCESS_TOKEN"];
    expect(token, isNotNull);

    final tmiClient = TmiClient(
      username: "SebbDev",
      channels: ["SebbDev"],
      token: token!,
      logs: true,
    );
    tmiClient.connect();

    await Future.delayed(const Duration(seconds: 10));

    try {
      await expectLater(tmiClient.connected, true);
    } catch (e) {
      tmiClient.dispose();
      rethrow;
    }
  });
}
