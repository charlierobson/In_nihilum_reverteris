import java.util.regex.Pattern;
import java.util.regex.Matcher;

class BMFont {
  String[] _data;
  int[] _offsets;
  int _glyphWidth, _glyphHeight;

  boolean fromBDF(String filename) {
    _data = loadStrings(filename);
    _offsets = new int[0];

    Pattern p = Pattern.compile("FONTBOUNDINGBOX (\\d*) (\\d*) \\d* [+-]\\d*");

    int idx = 0;
    for (String statement : _data) {
      if (statement.startsWith("BITMAP")) {
        _offsets = append(_offsets, idx + 1);
      } else {
        Matcher m = p.matcher(statement);
        if (m.matches()) {
          _glyphWidth = Integer.valueOf(m.group(1));
          _glyphHeight = Integer.valueOf(m.group(2));
          println(m.group(1), m.group(2));
        }
      }
      ++idx;
    }
    println(_offsets.length);

    return _data != null && _data.length > 0;
  }

  void toBDF(String filename) {
    saveStrings(filename, _data);
  }

  void addGlyph(int[] rows) {
    int gnum = _offsets.length;
    println(gnum);
    _offsets = append(_offsets, 0);
    _data = append(_data, "STARTCHAR");
    _data = append(_data, "ENCODING " + String.valueOf(gnum));
    _data = append(_data, "BITMAP");
    for (int i = 0; i < rows.length; ++i) {
      _data = append(_data, String.format("%02X", rows[i]));
    }
  }

  int glyphCount() {
    return _offsets.length;
  }

  int glyphWidth() {
    return _glyphWidth;
  }

  int glyphHeight() {
    return _glyphHeight;
  }

  int[] glyphData(int n) {
    int offset = _offsets[n];
    int[] gd = new int[_glyphHeight];
    for (int i = 0; i < _glyphHeight; ++i) {
      gd[i] = Integer.valueOf(_data[offset + i], 16);
    }
    return gd;
  }
}