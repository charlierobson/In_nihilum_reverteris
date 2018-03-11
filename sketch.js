var fontBitmap;
var chapter;
var font;
var worder;
let chapt = [];
var pages = [];
var jumps = [];
var page;

var input, button, greeting;

var fns = '0123456789ABCDEFGHIJKL';
var cinfns = 0;

blobs = [];

function preload() {
  fontBitmap = loadImage('textgamefont.bmp');
}


function setup() {
  let canvas = createCanvas(256,192);
  canvas.position(8,8);

  font = new Font(fontBitmap, 6, 11);
  font.createGlyphs();

  input = createInput();
  input.position(20, 220);

  button = createButton('load');
  button.position(input.x + input.width, input.y);
  button.mousePressed(loadText);

  loadStrings('md/'+fns.charAt(cinfns)+'.md', processChapter);
}

function processChapter(result) {
  worder = new Slicer(result.join('\n\n'));

  page = 0;

  pages = [];
  jumps = [];

  while (redrawx()) {
    ++page;
  }

  chapt.push('chp_' + fns.charAt(cinfns) + ':');
  for (p in pages) {
    chapt.push('\tPG\t' + pages[p]);
    chapt.push('\tJP\t' + jumps[p]);
  }

  cinfns++;
  if (cinfns < fns.length) {
    loadStrings('md/'+fns.charAt(cinfns)+'.md', processChapter);
  }
  else {
    saveStrings(chapt, 'chapterdat.asm');
  }
}


function draw() {
}

function loadText() {
  var name = input.value();
  chapter = loadStrings('md/'+name+'.md', reloaded);
}

function reloaded(result) {
  worder = new Slicer(result.join('\n\n'));
  pages = [0];
  page = 0;

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
  background(255);

  let localjumps = [];

  let pos = new pospair();
  pos.x = 0;
  pos.y = 0;

  let word = worder.peekWord();
  while (word == '\n') { worder.popWord(); word = worder.peekWord(); }
  if (word == '') return false;

  let pagestart = worder.cursor;
  while(word != '' && pos.y < height - 11) {

    let linkFinder = /(\s*)(\[\S)(\S+)/
    let match = word.match(linkFinder);
    if (match != null) {
      localjumps.push('cp'+match[2][1]);
      word = word.replace(linkFinder, '$1$3');
      let base = 2 * localjumps.length + 26;
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

  pages.push(pagestart);
  while (localjumps.length < 2) {
    localjumps.push(-1);
  }
  jumps.push(localjumps);

  return true;
}

function keyPressed() {
  if (keyCode === LEFT_ARROW) {
    if (page > 0) {
      --page;
      redrawx();
    }
  } else if (keyCode === RIGHT_ARROW) {
    if (page < pages.length - 1) {
      ++page;
      redrawx();
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
