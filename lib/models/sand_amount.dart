/// Drop volume for a single sand piece.
enum SandAmount {
  s(48, 'S', 0.42),
  m(100, 'M', 0.62),
  l(168, 'L', 0.82),
  xl(260, 'XL', 1.0);

  const SandAmount(this.grainCount, this.label, this.previewScale);

  final int grainCount;
  final String label;
  final double previewScale;
}
