class EventAttachment {
  final String? fileUrl;
  final String? title;
  final String? mimeType;
  final String? iconLink;
  final String? fileId;

  const EventAttachment({
    this.fileUrl,
    this.title,
    this.mimeType,
    this.iconLink,
    this.fileId,
  });

  factory EventAttachment.fromJson(Map<String, dynamic> json) {
    return EventAttachment(
      fileUrl: json['fileUrl'] as String?,
      title: json['title'] as String?,
      mimeType: json['mimeType'] as String?,
      iconLink: json['iconLink'] as String?,
      fileId: json['fileId'] as String?,
    );
  }

  bool get isImage => (mimeType?.startsWith('image/') ?? false);
}


