function Font(bitmap, gw, gh) {
    this.glyphs = [];
    this.glyphWidths = [];
    this.bitmap = bitmap;

    this.createGlyphs = function() {
        let rows = this.bitmap.height / gh;
        let columns = this.bitmap.width / gw;
        for (var y = 0; y < rows; ++y) {
            for (var x = 0; x < columns; ++x) {
                let i = createImage(gw, gh);
                i.copy(this.bitmap, x * gw, y * gh, gw, gh, 0, 0, gw, gh);
                this.glyphs.push(i);
                w = this.calculateCharWidth(i);
                this.glyphWidths.push(w);
            }
        }
        this.glyphWidths[32] = 4;  
    }
  
    this.calculateCharWidth = function(glyphImg) {
      var w = glyphImg.width;
      glyphImg.loadPixels();
      for (var x = 0; x < glyphImg.width; ++x) {
        let xo = (glyphImg.width - 1 - x) * 4;
        let yo = 0;
        for (var y = 0; y < glyphImg.height; ++y) {
          let col = glyphImg.pixels[xo + yo];
          yo += glyphImg.width * 4;
          if (col == 0) {
            return w + 1;
          }
        }
        --w;
      }
      return 0;
    };
  
    this.sanitise = function(code) {
        if (code > 255) {
            if (code == 8217) { 
                return 0xa5;
            }
            print(code);
            return 0;
        }
        return code;
    }

    this.glyphWidth = function(charNum) {
        return this.glyphWidths[this.sanitise(charNum)];
    };

    this.glyph = function(charNum) {
        return this.glyphs[this.sanitise(charNum)];
    };

    this.wordWidth = function(word) {
        var w = 0;
        for(i in word) {
            var c = this.sanitise(word.charCodeAt(i));
            w += this.glyphWidth(c);
        }
        return w;
    }
};
