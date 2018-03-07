# Yerzmyey - In nihilum reverteris

* Convert original .ODT file into github-flavoured markdown using [PANDOC](https://pandoc.org/).
  * pandoc -f odt -t gfm [original text].odt --wrap=none > y2.md
* Correct minor conversion niggles such as the asterisk-ellipses and anchor span at the end of the document.
* Upload converted text for review to [@TEXT](https://github.com/charlierobson/textgame/wiki/@-Text) page.
* Converted text has UTF-8 characters: ['\x93', '\x98', '\x99', '\x9c', '\x9d']. 
  * en-dash, left single quote, right single quote, left double quote, right double quote
* remove utf-8 streams using:
  * cat converted.md | iconv -t ASCII//TRANSLIT > rawtext.md
* Upload de-utf'd text for review to [@TEXT-no-utf](https://github.com/charlierobson/textgame/wiki/@Text-no-utf).
* Run de-utf'd text through a parser - take the text and generates a file per chapter block
  * exmeta.py 
* Compile images, music, text sections into WAD
* Just write a player
