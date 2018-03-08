var img;
var fontBitmap;
var chapter;
var font;
var worder;

function preload() {
  fontBitmap = loadImage('textgame.bmp');

  img = loadImage('bmp/0START.bmp');
  chapter = loadStrings('md/0.md');
}

function setup() {
  createCanvas(256,192);

  font = new Font(fontBitmap, 6, 11);
  font.createGlyphs();

  worder = new Slicer(chapter.join('\n'));

  var x = 0;
  var y = 0;

  var word = worder.peekWord();
  while(word != '' && y < height - 11) {
    var w = font.wordWidth(word);
    var spaceLeft = (width - x) >= w;
    if (w != 0) {
      if (!spaceLeft) {
        x = 0;
        y += 11;
        if (word[0] == ' ') {
          word = word.substring(1);
        }
      }
      if(y < height - 11) for(i in word) {
        image(font.glyph(word.charCodeAt(i)), x, y);
        x += font.glyphWidth(word.charCodeAt(i));
      }
    }
    else if (word == '\n') {
      x = 0;
      y += 11;
    }

    worder.popWord();
    word = worder.peekWord();
  }
}

function draw() {
}
