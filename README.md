# Yerzmyey - In nihilum reverteris

* Convert original .ODT file into github-flavoured markdown using [PANDOC](https://pandoc.org/).
  * pandoc -f odt -t gfm [original text].odt --wrap=none > y2.md
* Correct minor conversion niggles such as the asterisk ellipses and anchor span at the end of the document.
* Upload converted text for review to [@TEXT](https://github.com/charlierobson/textgame/wiki/@-Text) page.
* Run converted text through the parser - take the text and generates a file per chapter block
  * exmeta.py converted.md
* UTF-8 characters found are dumped so that suitable font entries and conversion code can be made. See table 1.
* Compile images, music, text sections into WAD
* Just write a player
  
  
#### Table 1
| UTF-8 character | Hex code stream |
|:-:|---|
| “ | 0xe2 0x80 0x9c |
| ’ | 0xe2 0x80 0x99 |
| ” | 0xe2 0x80 0x9d |
| ‘ | 0xe2 0x80 0x98 |
| â | 0xc3 0xa2 |
| é | 0xc3 0xa9 |
| à | 0xc3 0xa0 |
| á | 0xc3 0xa1 |
| è | 0xc3 0xa8 |
| ö | 0xc3 0xb6 |
| – | 0xe2 0x80 0x93 |
| ê | 0xc3 0xaa |
