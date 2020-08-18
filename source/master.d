module master;

import std.process;
import std.file;
import std.stdio;
import std.path;
import std.algorithm;


void main(string[] args)
{
    string path;
    string[] importPaths;
    string[] params;

    if (args.length < 3)
    {
        writeln("Please provide path to file or directory and import path");
        return;
    }
    else
    {
        path = args[1];
        if (!exists(path))
        {
            writeln("Invalid path");
            return;
        }
        for (int i = 2; i < args.length; i++)
            importPaths ~= args[i];
    }

    if (exists("results"))
        rmdirRecurse("results");

    mkdir("results");

    if(isDir(path))
    {
        auto dFiles = dirEntries(path, "*.d", SpanMode.depth);
        foreach (d; dFiles)
        {
            params = [];
            params ~= "./nogcov_worker";
            params ~= d.name;
            params ~= importPaths;
            auto worker = execute(params, null, Config.stderrPassThrough);
            if (worker.status != 0)
                    writeln("Analysis failed!");
            writeln(worker.output);
        }
    }
    else if(isFile(path))
    {
        if (!endsWith(path, ".d"))
            return;
        params ~= "./nogcov_worker";
        params ~= path;
        params ~= importPaths;
        auto worker = execute(params, null, Config.stderrPassThrough);
        if (worker.status != 0)
                writeln("Analysis failed!");
        writeln(worker.output);
    }
}
