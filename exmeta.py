import re
import sys

def showUTF(s, m):
    b = bytearray()
    b.extend(s)
    b.extend({0,0,0})
    bb = 0
    while bb < len(b):
        if b[bb] > 0x7f:
            if (b[bb] & 0xf0) == 0xc0: # 2 byte
                #print hex(b[bb]),hex(b[bb+1])
                #print "%s" % (b[bb:bb+2]),
                if not str(b[bb:bb+2]) in m:
                    print "   ", b[bb:bb+2], "    ", hex(b[bb]),hex(b[bb+1])
                m.add(str(b[bb:bb+2]))
                bb = bb + 1
            if (b[bb] & 0xf0) == 0xe0: # 3 byte
                #print hex(b[bb]),hex(b[bb+1]),hex(b[bb+2])
                #print "%s" % (b[bb:bb+3]),
                if not str(b[bb:bb+3]) in m:
                    print "   ", b[bb:bb+3], "    ", hex(b[bb]),hex(b[bb+1]),hex(b[bb+2])
                m.add(str(b[bb:bb+3]))
                bb = bb + 2
        bb = bb + 1
    return


if len(sys.argv) < 2:
    print
    print "Usage: exmeta.py [text file]"
    print
    exit(0)

with open(sys.argv[1]) as f:
    content = f.readlines()

blocks = {}
textData = list()
keyName = ''

m = set()

print "utf-8 characters found:"
print

for s in content:
    # if the line is a single character then we have a section name
    if re.match('^(.)$', s) != None:
        # add the previous section's accumulated text to the dictionary under the last key we found
        if keyName != '':
            blocks[keyName] = textData
        # reset for the next block
        textData = []
        keyName = s.strip()
    else:
        # accumulate some text
        textData.append(s)
        showUTF(s, m)

    # snaffle up the last block
    blocks[keyName] = textData

# we now have a dictionary that maps the section name to the text within it
for key in blocks.keys():
    out = open(key+".md", "w")
    for s in blocks[key]:
        out.write(s)
    out.close()

print
print "OK."
