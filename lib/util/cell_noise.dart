/// Tiny integer hash for grain sparkle / peek-through without storing extra maps.
int cellHash(int x, int y, int seed) {
  var h = x * 374761393 + y * 668265263 + seed * 1274126177;
  h = (h ^ (h >> 13)) * 1274126177;
  h ^= h >> 16;
  return h;
}

double cellNoise(int x, int y, int seed) {
  return (cellHash(x, y, seed) & 0xFFFF) / 0xFFFF;
}
