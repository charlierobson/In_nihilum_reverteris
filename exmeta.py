import re
import sys
import json

threebyte  = { 0x93: 0x2d, 0x98: 0x0f, 0x99: 0x10, 0x9c: 0x11, 0x9d: 0x12 }
twobyte = { 0xa0: 0x13, 0xa1: 0x14, 0xa2: 0x15, 0xa8: 0x16, 0xa9: 0x17, 0xaa: 0x18, 0xb6: 0x19 }

def sanitise(s):
    b = bytearray()
    b.extend(s)
    bb = 0
    outS = ''
    while bb < len(b):
        bo = b[bb]
        if bo > 0x7f:
            if (bo & 0xf0) == 0xc0: # 2 byte
                bo = twobyte[b[bb+1]]
                bb += 1
            if (bo & 0xf0) == 0xe0: # 3 byte
                bo = threebyte[b[bb+2]]
                bb += 2
        if bo != 0 and bo != 0x5c:
            outS += chr(bo)
        bb += 1
    return outS

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


def storeBlock(textData):
    textData[0] = textData[0].lstrip();
    textData[len(textData) - 1] = textData[len(textData) - 1].rstrip();
    blocks[keyName] = textData



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

for s in content:
    # if the line is a single character then we have a section name
    matc = re.match('^(.)$', s)
    if matc != None:
        # add the previous section's accumulated text to the dictionary under the last key we found
        if keyName != '':
            storeBlock(textData)
        # reset for the next block
        textData = []
        keyName = s.strip()
    else:
        s = s.rstrip() + '\n'
        # accumulate some text
        ###showUTF(s, m)
        textData.append(sanitise(s).decode('ascii'))

# snaffle up the last block
storeBlock(textData)

# we now have a dictionary that maps the section name to the text within it
for key in blocks.keys():
    out = open(key+".md", "w")
    for s in blocks[key]:
        out.write(s)
    out.close()
