import re
import sys

twobyte   = {0xa0: 0x86, 0xa1: 0x87, 0xa2: 0x88, 0xa8: 0x89, 0xa9: 0x8a, 0xaa: 0x8b, 0xb6: 0x85}
threebyte = {0x93: 0x84, 0x98: 0x82, 0x99: 0x83, 0x9c: 0x80, 0x9d: 0x81}

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

print "utf-8 characters found:"
print

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
        # accumulate some text
        showUTF(s, m)
        textData.append(sanitise(s))

# snaffle up the last block
storeBlock(textData)

# we now have a dictionary that maps the section name to the text within it
for key in blocks.keys():
    out = open(key+".md", "w")
    for s in blocks[key]:
        out.write(s)
    out.close()

print
print "OK."
