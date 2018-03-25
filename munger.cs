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
        private const int screenLines = 16;

        private int _jumpIdx;
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
            chardict[0x09] = "    ";
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

            SplitMD();
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
            outbytes.AddRange(new byte[0x230]);

            var italic = false;
            foreach(var b in bytes) {
                if (b == '*') {
                    italic = !italic;
                    continue;
                }

                int add = 0;
                if (italic && b > 14 && b != 32 && b != '.') {
                    add = 128;
                }
                outbytes.Add((byte)(b + add));
            }
            return outbytes.ToArray();
        }

        private int _maxLines;
        private byte[] charWidths;
        private Dictionary<String, int[]> jumps;

        public void SplitMD()
        {
            var chapters = new Dictionary<string, string>();

            var rawMD = File.ReadAllLines("converted.md");
            var charWidthsN = File.ReadAllBytes("textgamefont-widths.bin");
            var charWidthsI = File.ReadAllBytes("textgamefont-i-widths.bin");

            charWidths = charWidthsN.Concat(charWidthsI).ToArray();

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
                raw = raw.Replace("“You could well be right...” he sighed.", "*“You could well be right...” he sighed.*");

                var match = chapterMatcher.Match(raw);
                if (match.Success) {
                    if (accumulatedText.Length != 0) {
                        chapters[currentChapterName] = "\t" + accumulatedText.ToString().Trim();
                    }
                    currentChapterName = match.Groups[1].Captures[0].ToString();
                    accumulatedText.Clear();
                } else {
                    if (raw.Length > 1) raw = (char)9 + raw;
                    accumulatedText.AppendLine(raw);
                }
                ++line;
            }

            chapters[currentChapterName] = "\t" + accumulatedText.ToString().Trim();

            jumps = new Dictionary<String, int[]>();

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
                while(jumpData.Count < 3) {
                    jumpData.Add(0xff);                    
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

                File.WriteAllText("md/" + chapterName + ".md", chapters[chapterName]);
                File.WriteAllBytes("md/" + chapterName + ".mdx", xlat(chapters[chapterName]));
            }

            var chapterdat = new List<string>();

            chapterdat.Add(".define PAGE .byte");
            chapterdat.Add(".define JUMP .byte");
            chapterdat.Add(".define BMAP .byte");

            _maxLines = 0;

            foreach (var chapterName in chapterIDs)
            {
                var textBytes = File.ReadAllBytes("md/" + chapterName + ".mdx");

                ProcessChapterNew(chapterName, chapterdat, textBytes);

                File.WriteAllBytes("md/" + chapterName + ".mdx", textBytes);
            }

            Console.WriteLine("Writing chapterdat.asm");
            File.WriteAllLines("codegen/chapterdat.asm", chapterdat);

            chapterdat.Clear();
            chapterdat.Add("SPC_WIDTH .equ 4");
            chapterdat.Add("TAB_WIDTH .equ 16");
            chapterdat.Add($"LOWDATSTART .equ $3A00");
            chapterdat.Add($"SCREENLINES .equ {screenLines}");
            File.WriteAllLines("codegen/global.inc", chapterdat);
        }

        void ProcessChapterNew(string chapterName, List<string> chapterdat, byte[] textBytes)
        {
            LogV($"\n-------------- CHAPTER - {chapterName} --------------\n");

            var cn2idx = "0123456789ABCDEFGHIJKL";
            var intidx = cn2idx.IndexOf(chapterName);
            chapterdat.Add($"chp_{intidx}:  ;  {chapterName}");

            var bm2idx = "01589DEFHK";
            intidx = bm2idx.IndexOf(chapterName);
            chapterdat.Add($"\tBMAP\t{File.Exists($"bmp/{chapterName}.pbm") ? intidx : -1}");
            chapterdat.Add($"\tJUMP\t${jumps[chapterName][0]:x2}, ${jumps[chapterName][1]:x2}, ${jumps[chapterName][2]:x2}");

            var n = 0;
            var curStash = 0x230;
            var cursor = curStash;
            var lastBreak = curStash;

            do
            {
                var x = 0;
                while (x < 255)
                {
                    byte b = textBytes[cursor];
                    if (b == 32 || b == 10 || b == 0) {
                        lastBreak = cursor;
                    }
                    if (b == 10) {
                        break;
                    }
                    if (b == 0) {
                        break;
                    }
                    x += charWidths[textBytes[cursor] & 0x7f] + 1;
                    ++cursor;
                }

                // line runs from curstash -> lastBreak
                textBytes[n++] = (byte)(lastBreak-curStash);
                textBytes[n++] = (byte)(curStash & 255);
                textBytes[n++] = (byte)(curStash / 256);

 //               var ll = GetString(textBytes.Skip(curStash).Take(lastBreak-curStash).ToArray());
//                LogV($"{lastBreak-curStash,2}  {ll}\n");

  //              if ((n/3) % screenLines == 0) {
    //                LogV("--------------------\n");
      //          }

                curStash = lastBreak + 1;
                cursor = curStash;
                lastBreak = cursor;
            }
            while(textBytes[lastBreak - 1] != 0);

            var lc = n / 3;
            var o = 0;
            var pn = 0;
        
            do {
                LogV($"-- Page {pn} ----------------------------\n");
                for (int i = 0; i < screenLines; ++i) {
                    int nn = textBytes[3 * (o+i)];
                    int ppt = textBytes[3 * (o+i) + 1] + 256 * textBytes[3 * (o+i) + 2];
                    var ll = GetString(textBytes.Skip(ppt).Take(nn).ToArray());
                    LogV($"{nn,2}  {ll}\n");
                }

                chapterdat.Add($"\tPAGE\t${o:x2}");
                o += screenLines;
//                if (textBytes[3 * o] == 0) {
  //                  ++o;
    //            }
                ++pn;
            }
            while (o < lc);

            chapterdat.Add($"\tPAGE\t-1");

            if (_maxLines < lc) {
                _maxLines = lc;
            }
            LogV($"\nLines: {lc}, max {_maxLines}\n");
        }
    }
}
