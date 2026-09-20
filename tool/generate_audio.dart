import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

/// Generates lightweight placeholder WAV files so BGM/SE work without art assets.
void main() {
  _write('assets/audio/se_sand_drop.wav', _noiseBurst(0.16, 0.55, 1800, 0.35));
  _write('assets/audio/se_sand_slide.wav', _noiseBurst(0.32, 0.4, 1200, 0.5));
  _write('assets/audio/se_clear.wav', _arpeggio(const [523.25, 659.25, 783.99], 0.12));
  _write('assets/audio/se_chain.wav', _arpeggio(const [659.25, 783.99, 987.77, 1174.66], 0.1));
  _write('assets/audio/atelier/bgm.wav', _loopingBgm(atelier: true));
  _write('assets/audio/resort/bgm.wav', _loopingBgm(atelier: false));
  stdout.writeln('Audio placeholders written.');
}

void _write(String path, List<double> samples) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(_pcm16Wav(samples, 22050));
}

List<double> _noiseBurst(double seconds, double amp, double cutoffHint, double rumble) {
  final n = (22050 * seconds).round();
  final rng = Random(cutoffHint.toInt());
  var low = 0.0;
  return List<double>.generate(n, (i) {
    final t = i / n;
    final env = sin(pi * t.clamp(0.0, 1.0));
    final white = rng.nextDouble() * 2 - 1;
    low = low * rumble + white * (1 - rumble);
    return (low * 0.7 + white * 0.3) * amp * env;
  });
}

List<double> _arpeggio(List<double> freqs, double noteSec) {
  final samples = <double>[];
  for (final f in freqs) {
    final n = (22050 * noteSec).round();
    for (var i = 0; i < n; i++) {
      final t = i / 22050;
      final env = sin(pi * (i / n));
      samples.add(sin(2 * pi * f * t) * 0.28 * env);
    }
  }
  return samples;
}

List<double> _loopingBgm({required bool atelier}) {
  const sr = 22050;
  const seconds = 8.0;
  final n = (sr * seconds).round();
  final root = atelier ? 293.66 : 146.83;
  final scale = atelier
      ? const [0, 2, 4, 7, 9]
      : const [0, 3, 7, 10, 12];
  return List<double>.generate(n, (i) {
    final t = i / sr;
    final step = scale[(i ~/ (sr * (atelier ? 0.5 : 0.8))) % scale.length];
    final freq = root * pow(2, step / 12);
    final pad = sin(2 * pi * freq * 0.5 * t) * (atelier ? 0.08 : 0.10);
    final melody = sin(2 * pi * freq * t) * (atelier ? 0.12 : 0.07);
    final shimmer = sin(2 * pi * freq * 2 * t) * (atelier ? 0.02 : 0.03);
    final env = 0.65 + 0.35 * sin(2 * pi * t / seconds);
    return (pad + melody + shimmer) * env;
  });
}

Uint8List _pcm16Wav(List<double> samples, int sampleRate) {
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);
  var o = 0;
  void ascii(String s) {
    for (final c in s.codeUnits) {
      bytes.setUint8(o++, c);
    }
  }

  ascii('RIFF');
  bytes.setUint32(o, 36 + dataSize, Endian.little);
  o += 4;
  ascii('WAVE');
  ascii('fmt ');
  bytes.setUint32(o, 16, Endian.little);
  o += 4;
  bytes.setUint16(o, 1, Endian.little);
  o += 2;
  bytes.setUint16(o, 1, Endian.little);
  o += 2;
  bytes.setUint32(o, sampleRate, Endian.little);
  o += 4;
  bytes.setUint32(o, sampleRate * 2, Endian.little);
  o += 4;
  bytes.setUint16(o, 2, Endian.little);
  o += 2;
  bytes.setUint16(o, 16, Endian.little);
  o += 2;
  ascii('data');
  bytes.setUint32(o, dataSize, Endian.little);
  o += 4;
  for (final s in samples) {
    final v = (s.clamp(-1.0, 1.0) * 32767).round();
    bytes.setInt16(o, v, Endian.little);
    o += 2;
  }
  return bytes.buffer.asUint8List();
}
