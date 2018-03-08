import re
import os
import sys

verbose = None

# Edit the target font using 'raster font editor'
#   http://www.cylog.org/graphics/rasterfonteditor.jsp
#
# Maintain the source font in .FNT format. Adjust the range
# to include only the glyphs you need in the font details.

# Parses a human-readable 'BDF' format font file, described here:
#   https://en.wikipedia.org/wiki/Glyph_Bitmap_Distribution_Format

# Produces a binary font file, which is a raw dump of the bitmap
# bits, padded to the nearest 8. There are [glyph height]+1 bytes
# stored per glyph, where the +1 byte is the calculated width of
# the glyph.

# Onwards.

# open the source font file
with open(sys.argv[1]) as f:
    content = f.readlines()

# open the destination, using the input with the extension changed
fontfile = open(os.path.splitext(sys.argv[1])[0] + '.bin', 'wb')

i = 0
height = 0
minidx = 256
maxidx = 0

while i < len(content):
    s = content[i].strip()

    match = re.search('FONTBOUNDINGBOX (\d+) (\d+) (\d+) [+-]*(\d+)', s)
    if match:
        height = int(match.group(2))
        print 'Font height: ',height

    # find the next glyph
    match = re.search('ENCODING (\d+)', s)
    if match:
        # get the glyph index 0..255
        idx = int(match.group(1))

        # keep track of the character range found
        if idx < minidx:
            minidx = idx
        if idx > maxidx:
            maxidx = idx

        # search forward for the bitmap data itself
        while s != 'BITMAP':
            s = content[i].strip()
            i += 1

        # copy out [glyph height] bytes to the output file
        # OR together all the bytes to track all the used bits
        aggregate = 0
        for n in range(height):
            b = int(content[i].strip(), 16)
            fontfile.write(chr(b))
            aggregate |= b
            i += 1

        # see which is the lowest used bit number
        # this tells us the glyph width
        w = 0
        n = 1
        mask = 0x80
        while mask != 0:
            if (aggregate & mask):
                w = n
            n = n + 1
            mask >>= 1

        # something for the user to see
        if verbose:
            print 'Char',idx, w
        fontfile.write(chr(w))

    i += 1

print 'Glyph range:', minidx, maxidx
