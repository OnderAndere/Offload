/// The two export formats (T7.3, PO 09-10-2026): one per export, each as
/// one file.
enum ExportFormat {
  markdown('md', 'text/markdown'),
  json('json', 'application/json');

  const ExportFormat(this.extension, this.mimeType);

  /// The file extension, without the dot.
  final String extension;
  final String mimeType;
}
