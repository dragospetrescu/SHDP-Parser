module master;

import std.process;
import std.file;
import std.stdio;
import std.path;
import std.algorithm;


void main(string[] args)
{
    string path;
    string securityLevel;
    string[] importPaths;
    string[] params;


    if (args.length < 3)
    {
        writeln("Please provide path to file or directory and import path");
        return;
    }
    else
    {
        securityLevel = args[1];
        path = args[2];
        if (!exists(path))
        {
            writeln("Invalid path");
            return;
        }

        for (int i = 3; i < args.length; i++)
            importPaths ~= args[i];
    }

    if(isDir(path))
    {
        auto dFiles = dirEntries(path, "*.d", SpanMode.depth);
        foreach (d; dFiles)
        {
            params = [];
            params ~= "./nogcov_worker";
            params ~= securityLevel;
            params ~= d.name;
            params ~= importPaths;
            auto worker = execute(params, null, Config.stderrPassThrough);
            if (worker.status != 0)
                    writeln("Analysis failed!");
            if(worker.output.length != 0) {
              write(worker.output);
            }

        }
    }
    else if(isFile(path))
    {
        if (!endsWith(path, ".d"))
            return;
        params ~= "./nogcov_worker";
        params ~= securityLevel;
        params ~= path;
        params ~= importPaths;
        auto worker = execute(params, null, Config.stderrPassThrough);
        if (worker.status != 0)
                writeln("Analysis failed!");
        if(worker.output.length != 0) {
          write(worker.output);
        }
    }
}
