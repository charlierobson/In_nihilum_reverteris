PImage[] glyphs = new PImage[256];

void setup() {
  byte[] bmFont = loadBytes("../../textgamefont.bin");
  byte[] bmiFont = loadBytes("../../textgamefont-i.bin");

  size(1024, 768);

  background(240);

  noSmooth();
 
  for (int p = 0, n = 0; n < bmFont.length / 10; ++n) {
    PImage g = new PImage(8, 10);
    g.loadPixels();
    for (int r = 0, xo = 0; r < 10; ++r) {
      int gb = bmFont[p++];
      for (int b = 0x80; b != 0; b >>= 1) {
        g.pixels[xo++] = (gb & b) != 0 ? color(0) : color(240);
      }
    }
    g.updatePixels();
    glyphs[n+15] = g;
  }
  for (int p = 0, n = 0; n < bmiFont.length / 10; ++n) {
    PImage g = new PImage(8, 10);
    g.loadPixels();
    for (int r = 0, xo = 0; r < 10; ++r) {
      int gb = bmiFont[p++];
      for (int b = 0x80; b != 0; b >>= 1) {
        g.pixels[xo++] = (gb & b) != 0 ? color(0) : color(240);
      }
    }
    g.updatePixels();
    glyphs[n+15+128] = g;
  }
}

void draw() {
  background(255);
  for (int i = 0; i < 256; ++i) {
    int x = (i % 32) * 8;
    int y = (i / 32) * 11;
    if (glyphs[i] != null) {
      image(glyphs[i], x * 4, y * 4, 8 * 4, 11 * 4);
    }
  }
}