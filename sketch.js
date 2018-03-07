var img;
var font;
var glyphs = [];

function preload() {
  img = loadImage('./bmp/0START.bmp');
  font = loadImage('textgame.bmp')
}

function setup() {
  createCanvas(256,192);
  for (var y = 1; y < 8; ++y) {
    for (var x = 0; x < 32; ++x) {
      let i = createImage(6,11);
      i.copy(font, x * 6, y * 11, 6, 11, 0, 0, 6, 11);
      glyphs.push(i);
    }
  }
}

function draw() {
  let x = 8;
  let s = "HELLO WORLD! Now this is quite something!";
  for (var i = 0; i < s.length; i++) {
    let c = s.charCodeAt(i) - 32;
    image(glyphs[c], x, 0);
    x = x + 6;
  }
  image(img, 0, 16);
}
