pandoc -f odt -t gfm Yerzmyey-In_nihilum_reverteris.odt --wrap=none > converted.md
cat converted.md | iconv -t ASCII//TRANSLIT > rawtext.md
python exmeta.py
mv ?.md md/
