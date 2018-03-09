
var fontBitmap;
var chapter;
var font;
var worder;
var redrawRequired;
var pages = [];
var page;

var input, button, greeting;

function preload() {
  fontBitmap = loadImage('textgamefont.bmp');

  chapter = loadStrings('md/1.md');
}


function setup() {
  let canvas = createCanvas(256,192);
  canvas.position(8,8);

  font = new Font(fontBitmap, 6, 11);
  font.createGlyphs();

  worder = new Slicer(chapter.join('\n\n'));
  pages.push(worder.cursor);
  page = 0;

  input = createInput();
  input.position(20, 220);

  button = createButton('load');
  button.position(input.x + input.width, input.y);
  button.mousePressed(loadText);

  redrawRequired = true;
}

function draw() {
  if (!redrawRequired) return;
  redrawx();
}

function loadText() {
  var name = input.value();
  chapter = loadStrings('md/'+name+'.md', reloaded);
}

function reloaded(result) {
  worder = new Slicer(result.join('\n\n'));
  pages = [0];
  page = 0;

  redrawRequired = true;
  redrawx();
}

function pospair() {
  this.x = 0;
  this.y = 0;
}

function renderWord(word, pos) {
  let w = font.wordWidth(word);
  let spaceLeft = (width - pos.x) >= w;
  if (word === '\n' || !spaceLeft) {
    pos.x = 0;
    pos.y += 11;
    if (pos.y > height-11) return false;
  }
  
  if (pos.x == 0 && word[0] == ' ') {
    word = word.substring(1);
  }

  for(let i in word) {
    image(font.glyph(word.charCodeAt(i)), pos.x, pos.y);
    pos.x += font.glyphWidth(word.charCodeAt(i));
  }

  return true;
}

function redrawx() {
  redrawRequired = false;

  worder.cursor = pages[page];

  background(255);

  jumps = [];

  let pos = new pospair();
  pos.x = 0;
  pos.y = 0;

  let word = worder.peekWord();
  while (word == '\n') { worder.popWord(); word = worder.peekWord(); }

  while(word != '' && pos.y < height - 11) {

    let linkFinder = /(\s*)(\[\S)(\S+)/
    let match = word.match(linkFinder);
    if (match != null) {
      jumps.push(match[2][1]);
      word = word.replace(linkFinder, '$1$3');
      let base = 2 * jumps.length + 138;
      renderWord(' ' + (char)(base) + (char)(base+1), pos);
    }
    else {
      let iob = word.indexOf(']');
      if (iob > -1) {
        word = word.slice(0, iob) + word.substr(iob+1);
      }
    }

    if (!renderWord(word, pos)) {
      continue;
    }

    worder.popWord();
    word = worder.peekWord();
  }

  if (pages.length < page + 2 && word != '') {
    pages.push(worder.cursor);
  }

  print(jumps);
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

  if (jumps.length == 0) {
    return;
  }

  let A = 'A'.charCodeAt(0);
  if (keyCode >= A && keyCode < A + jumps.length) {
    chapter = loadStrings('md/'+jumps[keyCode - A]+'.md', reloaded);
  }
}
