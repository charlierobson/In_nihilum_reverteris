using System;
using System.IO;

public class WadMaker
{
    public static void Main(string[] args)
    {
        var program = new WadMaker();
        program.run(args);
    }

    private void run(string[] args)
    {
        var totesSize = 0L;

        var script = File.ReadAllLines(args[0]);
        foreach(var file in script) {
            var length = new FileInfo(file).Length;
            var wadsize = ((length + 255) / 256) * 256;
            totesSize += wadsize;
        }

        var idx = 0;
        var offset = 0L;

        var wad = new byte[totesSize];
        foreach(var file in script) {
            var bytes = File.ReadAllBytes(file);
            bytes.CopyTo(wad, offset);
            Console.WriteLine($"\t.word\t${offset/256:x4}\t\t; {idx:x2}  {file}");
            offset += ((bytes.Length + 255) / 256) * 256;
            ++idx;
        }

        File.WriteAllBytes(args[1], wad);
    }
}