# twitch_tmi

A dart package for interacting with the Twitch IRC chat.

## Features

TODO

## Getting started

TODO

## Usage

```dart
final client = TmiClient(
  channels: ["my_channel"],
  token: "123456789",
  autoPong: true,
  logs: true,
  logLevel: Level.info,
);

client.connect();

final subscription = client.listen((event) {
  // TODO : Do something with the event
});
```

## Additional information

TODO
