using System;
using System.IO;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;
using System.Linq;

namespace testapp1
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var program = new WadMaker();
            program.SplitMD();
            //program.MakeWAD(args);
        }
    }

    public class WadMaker
    {
        private int _jumpIdx;

        private void ConsoleWriteLine(string s)
        {
            //Console.WriteLine(s);
        }

        private void ConsoleWrite(string s)
        {
            //Console.Write(s);
        }

        public void SplitMD()
        {
            var chapters = new Dictionary<string, string>();
            var rawMD = File.ReadAllLines("/Users/charlierobson/Documents/GH/textgame/converted.md");
            var charWidths = File.ReadAllBytes("/Users/charlierobson/Documents/GH/textgame/textgamefont-widths.bin");

            var line = 0;
            var chapterMatcher = new Regex(@"^(\S)$");

            var accumulatedText = new StringBuilder();
            var currentChapterName = string.Empty;

            while (line < rawMD.Length) {
                var match = chapterMatcher.Match(rawMD[line]);
                if (match.Success) {
                    if (accumulatedText.Length != 0) {
                        chapters[currentChapterName] = accumulatedText.ToString().Trim();
                    }
                    currentChapterName = match.Groups[1].Captures[0].ToString();
                    accumulatedText.Clear();
                } else {
                    accumulatedText.AppendLine(rawMD[line]);
                }
                ++line;
            }

            var chapterIDs = new List<string>(chapters.Keys);
            foreach (var chapterName in chapterIDs)
            {
                chapters[chapterName] = chapters[chapterName].Replace('–', (char)(0x2d));

                chapters[chapterName] = chapters[chapterName].Replace('‘', (char)(0x0f));
                chapters[chapterName] = chapters[chapterName].Replace('’', (char)(0x10));
                chapters[chapterName] = chapters[chapterName].Replace('“', (char)(0x11));
                chapters[chapterName] = chapters[chapterName].Replace('”', (char)(0x12));

                chapters[chapterName] = chapters[chapterName].Replace('à', (char)(0x13));
                chapters[chapterName] = chapters[chapterName].Replace('á', (char)(0x14));
                chapters[chapterName] = chapters[chapterName].Replace('â', (char)(0x15));
                chapters[chapterName] = chapters[chapterName].Replace('è', (char)(0x16));
                chapters[chapterName] = chapters[chapterName].Replace('é', (char)(0x17));
                chapters[chapterName] = chapters[chapterName].Replace('ê', (char)(0x18));
                chapters[chapterName] = chapters[chapterName].Replace('ö', (char)(0x19));

                chapters[chapterName] = Regex.Replace(chapters[chapterName], @"\\\]", "");

                _jumpIdx = 0;
                chapters[chapterName] = Regex.Replace(chapters[chapterName], @"\\\[(\S)", m => {
                    var chartwodeetwo = new char[2];

                    chartwodeetwo[0] = (char)(_jumpIdx + 0x1a);
                    chartwodeetwo[1] = (char)(_jumpIdx + 0x1b);
                    var q = new string(chartwodeetwo);

                    _jumpIdx += 2;

                    return q + " ";
                });

                File.WriteAllText("/Users/charlierobson/Documents/gh/textgame/" + chapterName + ".mdx", chapters[chapterName]);
            }

            foreach (var chapterName in chapterIDs)
            {
                var textBytes = File.ReadAllBytes("/Users/charlierobson/Documents/gh/textgame/" + chapterName + ".mdx");

                const int numLines = 192 / 11;

                var curstash = 0;
                var cursor = curstash;

                Console.WriteLine($"chp_{chapterName}:");

                while (cursor < textBytes.Length)
                {
                    var x = 0; // cls ;)
                    var y = 0;
                    cursor = curstash;

                    while(textBytes[cursor] == 10 || textBytes[cursor] == 32) {
                        ++cursor;
                    }
                    bool jumpAFound = false;
                    bool jumpBFound = false;

                    Console.WriteLine($"\tPG\t${cursor:x4}");

                    ConsoleWriteLine($"\nCursor @ {cursor}");
                    while (cursor < textBytes.Length && y < numLines)
                    {
                        curstash = cursor;
                        var word = getWord(textBytes, ref cursor);
                        var dbgWord = Encoding.Default.GetString(word);

                        if (word[0] == 10)
                        {
                            x = 0;
                            ++y;
                            ConsoleWriteLine("");
                            continue;
                        }

                        var len = word.Aggregate(0, (total, next) => total + charWidths[next] + 1);
                        var remaining = 256 - x;
                        if (len > remaining)
                        {
                            x = 0;
                            ++y;
                            ConsoleWriteLine("");
                            if (y >= numLines)
                            {
                                continue;
                            }
                            if (word[0] == 32)
                            {
                                word =  word.Skip(1).Take(word.Length - 1).ToArray();
                                len -= charWidths[32];
                            }
                        }

                        x += len;
                        ConsoleWrite(Encoding.Default.GetString(word));
                        jumpAFound |= Array.Exists(word, element => element == 0x1a);
                        jumpBFound |= Array.Exists(word, element => element == 0x1c);

                    }
                    ConsoleWriteLine("");
                    Console.WriteLine($"\tJT\t{jumpAFound} {jumpBFound}");
                }
            }
        }

        public byte[] getWord(byte[] str, ref int cursor)
        {
            var word = new List<byte>();

            byte b;
            do
            {
                b = str[cursor];
                word.Add(b);
                ++cursor;
            }
            while (cursor != str.Length && b != 10 && str[cursor] != 32 && str[cursor] != 10);

            return word.ToArray();
        }

        public void MakeWAD(string[] args)
        {
            var totesSize = 0L;

            var script = File.ReadAllLines(args[0]);
            foreach (var file in script)
            {
                var length = new FileInfo(file).Length;
                var wadsize = ((length + 255) / 256) * 256;
                totesSize += wadsize;
            }

            var idx = 0;
            var offset = 0L;

            var wad = new byte[totesSize];
            foreach (var file in script)
            {
                var bytes = File.ReadAllBytes(file);
                bytes.CopyTo(wad, offset);
                Console.WriteLine($"\t.word\t${offset / 256:x4}\t\t; {idx:x2}  {file}");
                offset += ((bytes.Length + 255) / 256) * 256;
                ++idx;
            }

            File.WriteAllBytes(args[1], wad);
        }
    }
}