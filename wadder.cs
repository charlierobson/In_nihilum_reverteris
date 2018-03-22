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
            var p = new Program();
            p.Run();
        }

        public void Run()
        {
            MakeWAD();
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
                var lenny = (bytes.Length + 255) / 256;
                waddat.Add($"\t.word\t${offset / 256:x4}\t\t; {idx:x2}  {file}");
                waddat.Add($"\t.byte\t${lenny:x2}");
                offset += lenny * 256;
                ++idx;
            }

            Console.WriteLine("Writing tg.wad");
            File.WriteAllBytes("tg.wad", wad);

            Console.WriteLine("Writing wad.asm");
            File.WriteAllLines("codegen/wad.asm", waddat);
        }
    }
}
