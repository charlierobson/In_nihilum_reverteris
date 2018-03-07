pandoc -f odt -t gfm Yerzmyey-In_nihilum_reverteris.odt --wrap=none > converted.md
python exmeta.py converted.md
mv ?.md md/
