BMFont bmFont;

void setup() {
  bmFont = new BMFont();
  if (!bmFont.fromBDF("../../textgamefont.bdf")) {
    bmFont = null;
  }

  size(256, 192);

  background(240);
  loadPixels();

  int yo = 0;

  // show normal
  for (int n = 0, y = 0; y < bmFont.glyphCount() / 32; ++y) {
    for (int x = 0; x < 32; ++x, ++n) {
      int[] glyph = bmFont.glyphData(n);
      for (int r = 0; r < glyph.length; ++r) {
        int gb = glyph[r];
        for (int xo = 0, b = 0x80; xo < 8; xo++, b >>= 1) {
          pixels[x * 8 + ((((y + yo) * 12) + r) * width) + xo] = (gb & b) != 0 ? color(0) : color(240);
        }
      }
    }
  }

  yo = 4;
  // try italic
  for (int n = 0, y = 0; y < 128 / 32; ++y) {
    for (int x = 0; x < 32; ++x, ++n) {
      int[] glyph = bmFont.glyphData(n);
      int[] newglyph = new int[glyph.length];
      for (int r = 0; r < glyph.length; ++r) {
        int gb = glyph[r];
        gb = gb >> 3 - (r / 3);
        newglyph[r] = gb;
        for (int xo = 0, b = 0x80; xo < 8; xo++, b >>= 1) {
          pixels[x * 8 + ((((y + yo) * 12) + r) * width) + xo] = (gb & b) != 0 ? color(0) : color(240);
        }
      }
      bmFont.addGlyph(newglyph);
      println(bmFont.glyphCount());
    }
  }

  
/*
  yo = 8;
  // show bold
  for (int n = 0, y = 0; y < bmFont.glyphCount() / 32; ++y) {
    for (int x = 0; x < 32; ++x, ++n) {
      int[] glyph = bmFont.glyphData(n);
      for (int r = 0; r < glyph.length; ++r) {
        int gb = glyph[r];
        gb |= gb >> 1;
        for (int xo = 0, b = 0x80; xo < 8; xo++, b >>= 1) {
          pixels[x * 8 + ((((y + yo) * 12) + r) * width) + xo] = (gb & b) != 0 ? color(0) : color(240);
        }
      }
    }
  }
*/

  updatePixels();
 
   bmFont.toBDF("../../textgamefont2.bdf");
}

void draw() {
}