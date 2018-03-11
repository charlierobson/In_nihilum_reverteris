# Yerzmyey - In nihilum reverteris

* Convert original .ODT file into github-flavoured markdown using [PANDOC](https://pandoc.org/)
  * pandoc -f odt -t gfm \[original text\].odt --wrap=none > converted.md
* Correct minor conversion niggles such as the asterisk ellipses and anchor span at the end of the document.
* Commit in the converted text.
* [Check the converted text](https://github.com/charlierobson/textgame/blob/master/converted.md)
* Run converted text through the parser - take the text and generates a file per chapter block
  * exmeta.py converted.md
* Commit the text blocks.
* UTF-8 characters found are dumped so that suitable font entries and conversion code can be made.
  * Compare list to Table 1. Update table if required.

Todo:  
* Compile images, music, text sections into WAD
* Just write a player
  
  
#### Table 1
| UTF-8 character | Hex code stream |
|:-:|---|
| – | 0xe2 0x80 0x93 |
| ‘ | 0xe2 0x80 0x98 |
| ’ | 0xe2 0x80 0x99 |
| “ | 0xe2 0x80 0x9c |
| ” | 0xe2 0x80 0x9d |
| à | 0xc3 0xa0 |
| á | 0xc3 0xa1 |
| â | 0xc3 0xa2 |
| è | 0xc3 0xa8 |
| é | 0xc3 0xa9 |
| ê | 0xc3 0xaa |
| ö | 0xc3 0xb6 |
