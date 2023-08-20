class Parameters {
  final String raw;
  final String message;
  final bool isAction;
  final bool isMention;

  Parameters({
    required this.raw,
    this.message = "",
    this.isAction = false,
    this.isMention = false,
  });
}
