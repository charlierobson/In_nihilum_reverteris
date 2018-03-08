var img;
var fontBitmap;
var chapter;
var font;
var worder;
var redrawRequired;
var pages = [];
var page;

function preload() {
  fontBitmap = loadImage('textgamefont.bmp');

  img = loadImage('bmp/0START.bmp');
  chapter = loadStrings('md/2.md');
}


function setup() {
  createCanvas(256,192);

  font = new Font(fontBitmap, 6, 11);
  font.createGlyphs();

  worder = new Slicer(chapter.join('\n\n'));
  pages.push(worder.cursor);
  page = 0;

  redrawRequired = true;
}

function draw() {
  if (!redrawRequired) return;

  redrawRequired = false;

  worder.cursor = pages[page];

  background(200);

  var x = 0;
  var y = 0;

  var word = worder.peekWord();
  while(word != '' && y < height - 11) {
    let w = font.wordWidth(word);
    var spaceLeft = (width - x) >= w;
    if (word == '\n' || !spaceLeft) {
      x = 0;
      y += 11;

      if (!spaceLeft) continue;
    }

    if (x == 0 && word[0] == ' ') {
      word = word.substring(1);
    }

    for(i in word) {
      image(font.glyph(word.charCodeAt(i)), x, y);
      x += font.glyphWidth(word.charCodeAt(i));
    }

    worder.popWord();
    word = worder.peekWord();
  }

  if (pages.length < page + 2 && word != '') {
    pages.push(worder.cursor);
  }
}

function keyPressed() {
  if (keyCode === LEFT_ARROW) {
    if (page > 0) {
      --page;
      redrawRequired = true;
    }
  } else if (keyCode === RIGHT_ARROW) {
    if (page < pages.length - 1) {
      ++page;
      redrawRequired = true;
    }
  }
}
