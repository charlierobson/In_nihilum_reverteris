import re

with open("rawtext.md") as f:
    content = f.readlines()

blocks = {}
textData = list()
keyName = ''

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

    # snaffle up the last block
    blocks[keyName] = textData

# we now have a dictionary that maps the section name to the text within it
for key in blocks.keys():
    out = open(key+".md", "w")
    for s in blocks[key]:
        out.write(s)
    out.close()