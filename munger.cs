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
        private int _jumpIdx;
        private bool _italics;
        private Dictionary<byte, string> chardict;

        private static bool verbose;

        public static void Main(string[] args)
        {
            verbose = args.Length > 0 && args[0] == "V";

            var p = new Program();
            p.Run();
        }

        public void Run()
        {
            chardict = new Dictionary<byte, string>();
            chardict[0x0f] = "'";
            chardict[0x10] = "'";
            chardict[0x11] = "\"";
            chardict[0x12] = "\"";
            chardict[0x13] = "a";
            chardict[0x14] = "a";
            chardict[0x15] = "a";
            chardict[0x16] = "e";
            chardict[0x17] = "e";
            chardict[0x18] = "e";
            chardict[0x19] = "o";
            chardict[0x1a] = "[A";
            chardict[0x1b] = "]";
            chardict[0x1c] = "[B";
            chardict[0x1d] = "]";
            chardict[0x1e] = "[C";
            chardict[0x1f] = "]";
            chardict[0x7f] = "    ";

            SplitMD();
            MakeWAD();
        }

        private string GetString(byte[] source)
        {
            var sb = new StringBuilder();
            foreach (var b in source) {
                if (b >= 32 && b < 128) {
                    sb.Append((char)b);
                }
                if (b > 128) {
                    sb.Append("_" + (char)(b-128));
                } else if (chardict.Keys.Contains(b)) {
                    sb.Append(chardict[b]);
                }
            }
            return sb.ToString();
        }

        private void LogV(string s) {
            if (verbose) Console.Write(s);
        }

        private byte[] xlat(string x) {
            var bytes = Encoding.ASCII.GetBytes(x);
            List<byte> outbytes = new List<byte>();
            var italic = false;
            foreach(var b in bytes) {
                if (b == '*') {
                    italic = !italic;
                    continue;
                }
                outbytes.Add((byte)(b + (italic?128:0)));
            }
            return outbytes.ToArray();
        }

        public void SplitMD()
        {
            var chapters = new Dictionary<string, string>();
            var jumps = new Dictionary<String, int[]>();

            var rawMD = File.ReadAllLines("converted.md");
            var charWidthsX = File.ReadAllBytes("textgamefont-widths.bin");
            var charWidths = charWidthsX.Concat(charWidthsX).ToArray();

            var line = 0;
            var chapterMatcher = new Regex(@"^(\S)$");

            var accumulatedText = new StringBuilder();
            var currentChapterName = string.Empty;

            while (line < rawMD.Length) {
                var raw = rawMD[line];

                raw = raw.Replace("<span id=\"anchor\"></span>", "");
                raw = raw.Replace(@"\!", "!");
                raw = raw.Replace(@"\*", "*");
                raw = raw.Replace("tooth.* *", "tooth.");
                raw = raw.Replace("* * *", "                 # # #");
                raw = raw.Replace("*    *", "#    #");
                raw = raw.Replace("fickly-fiddle-dee-dee", "fickly-fiddle-dee- dee");
                raw = raw.Replace("facto *escape", "facto* escape");
                raw = raw.Replace("*fauna *and", "*fauna* and");
                raw = raw.Replace("exist*. *The", "exist. The");
                raw = raw.Replace("nothing *exist?", "nothing* exist?");
                raw = raw.Replace(" *absolute *void", " *absolute* void");
                raw = raw.Replace("only *one *Testament!", "only *one* Testament!");
                raw = raw.Replace(" *without Judith", "* without Judith");

                var match = chapterMatcher.Match(raw);
                if (match.Success) {
                    if (accumulatedText.Length != 0) {
                        chapters[currentChapterName] = accumulatedText.ToString().Trim();
                    }
                    currentChapterName = match.Groups[1].Captures[0].ToString();
                    accumulatedText.Clear();
                } else {
                    if (raw.Length > 1) raw = (char)(127) + raw;
                    accumulatedText.AppendLine(raw);
                }
                ++line;
            }

            chapters[currentChapterName] = accumulatedText.ToString().Trim();

            var chapterIDs = new List<string>(chapters.Keys);
            chapterIDs.Sort();
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

                var jumpData = new List<int>();

                var matches = new Regex(@"\\\[(?<cid>\S)").Matches(chapters[chapterName]);
                foreach (Match match in matches)
                {
                    var cn2idx = "0123456789ABCDEFGHIJKL";
                    var target = match.Groups["cid"].Value;
                    var intidx = cn2idx.IndexOf(target);
                    jumpData.Add(intidx);
                }

                jumps[chapterName] = jumpData.ToArray();

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

                chapters[chapterName] += '\0';

                Console.WriteLine("Writing " + chapterName + ".md");
                File.WriteAllText("md/" + chapterName + ".md", chapters[chapterName]);
                File.WriteAllBytes("md/" + chapterName + ".mdx", xlat(chapters[chapterName]));
            }

            var chapterdat = new List<string>();

            foreach (var chapterName in chapterIDs)
            {
                _italics = false;
                var textBytes = File.ReadAllBytes("md/" + chapterName + ".md");

                LogV($"-----------------CHAPTER-{chapterName}----------------\n");

                const int numLines = 192 / 11;

                var curstash = 0;
                var cursor = curstash;

                var cn2idx = "0123456789ABCDEFGHIJKL";
                var intidx = cn2idx.IndexOf(chapterName);
                chapterdat.Add($"chp_{intidx}:  ;  {chapterName}");

                var bm2idx = "01589DEFHK";
                intidx = bm2idx.IndexOf(chapterName);
                chapterdat.Add($"\tBMAP\t{File.Exists($"bmp/{chapterName}.pbm") ? intidx : -1}");

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
                    bool jumpCFound = false;

                    chapterdat.Add($"\tPAGE\t${cursor:x4}");
                    LogV("\n------------------------------\n");

                    while (cursor < textBytes.Length && y < numLines)
                    {
                        curstash = cursor;
                        var word = getWord(textBytes, ref cursor);

                        if (word[0] == 10)
                        {
                            x = 0;
                            ++y;
                            LogV("\n");
                            continue;
                        }

                        var len = word.Aggregate(0, (total, next) => total + charWidths[next] + 1) - 1;
                        if (x + len > 255)
                        {
                            x = 0;
                            ++y;
                            if (y >= numLines)
                            {
                                continue;
                            }
                            LogV("\n");
                            if (word[0] == 32)
                            {
                                word =  word.Skip(1).Take(word.Length - 1).ToArray();
                                len -= charWidths[32];
                            }
                        }

                        x += len;   
                        LogV(GetString(word));

                        jumpAFound |= Array.Exists(word, element => element == 0x1a);
                        jumpBFound |= Array.Exists(word, element => element == 0x1c);
                        jumpCFound |= Array.Exists(word, element => element == 0x1e);
                    }
                    chapterdat.Add($"\tJUMP\t{jumpAFound?jumps[chapterName][0]:-1},{jumpBFound?jumps[chapterName][1]:-1},{jumpCFound?jumps[chapterName][2]:-1}");
                }
                chapterdat.Add("\tPAGE\t-1");
                LogV("\n------------------------------\n");
            }

            Console.WriteLine("Writing chapterdat.asm");
            File.WriteAllLines("codegen/chapterdat.asm", chapterdat);
        }

        public byte[] getWord(byte[] str, ref int cursor)
        {
            var word = new List<byte>();

            byte b;
            do
            {
                b = str[cursor];
                ++cursor;
                if (b == '*') {
                    _italics = !_italics;
                    continue;
                }
                int add = 0;
                if (_italics && b > 14) {
                    add = 128;
                }
                word.Add((byte)(b + add));
            }
            while (cursor != str.Length && b != 10 && str[cursor] != 32 && str[cursor] != 10);

            return word.ToArray();
        }

        public void MakeWAD()
        {
            var totesSize = 0L;

            var script = File.ReadAllLines("script.txt");
            foreach (var file in script)
            {
                var length = new FileInfo(file).Length;
                var wadsize = ((length + 255) / 256) * 256;
                totesSize += wadsize;
            }

            var idx = 0;
            var offset = 0L;

            var waddat = new List<string>();

            var wad = new byte[totesSize];
            foreach (var file in script)
            {
                var bytes = File.ReadAllBytes(file);
                bytes.CopyTo(wad, offset);
                waddat.Add($"\t.word\t${offset / 256:x4}\t\t; {idx:x2}  {file}");
                offset += ((bytes.Length + 255) / 256) * 256;
                ++idx;
            }

            Console.WriteLine("Writing tg.wad");
            File.WriteAllBytes("tg.wad", wad);

            Console.WriteLine("Writing wad.asm");
            File.WriteAllLines("codegen/wad.asm", waddat);
        }
    }
}
