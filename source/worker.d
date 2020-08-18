module worker;

import dmd.parse;
import dmd.visitor;
import dmd.frontend;
import dmd.astbase;
import dmd.errors;
import dmd.dscope;
import dmd.dsymbol;
import dmd.globals;
import dmd.identifier;
import dmd.id;
import dmd.dmodule;
import dmd.visitor;
import dmd.func;
import dmd.astcodegen;
import dmd.expression;
import dmd.dtemplate;
import dmd.errors;
import dmd.arraytypes;
import dmd.mtype;
import dmd.root.outbuffer;

import std.file;
import std.string;
import std.range;
import std.stdio;
import std.algorithm;
import std.path;

extern(C++) class NogcCoverageVisitor : SemanticTimeTransitiveVisitor
{
    alias visit = SemanticTimeTransitiveVisitor.visit;
    Scope* sc;
    bool insideUnittest;
    string[][string] funcDict;

    this(Scope* sc)
    {
        this.sc = sc;
        this.insideUnittest = false;
    }


    override void visit(FuncDeclaration fd)
    {
      writeln(fd.toString());
    }
}

void nogcCoverageCheck(Dsymbol dsym, Scope* sc)
{
    OutBuffer buf;
    Module m = cast(Module)dsym;
    m.fullyQualifiedName(buf);

    string fullName = buf.extractSlice();


    scope v = new NogcCoverageVisitor(sc);
    dsym.accept(v);


}


void initTool(string[] importPaths)
{
    //Global.params must be set *before* initDMD();
    global.params.isLinux = true;
    global.params.is64bit = (size_t.sizeof == 8);
    global.params.useUnitTests = true;
    global.params.useDIP25 = true;
    global.params.vsafe = true;

    initDMD();

    /*
    Import paths should be added using addImport()
    because findImportPaths() might lead to conflicts
    between /usr/bin/phobos and /dlang/phobos
    */
    importPaths.each!addImport;
}

void deinitializeTool()
{
    deinitializeDMD();
}

Modules prepareModules(string path)
{
    Modules modules;
    if(isDir(path))
    {
        auto dFiles = dirEntries(path, SpanMode.depth);
        foreach (d; dFiles)
        {
            Module m = parseModule(d.name).module_;
            fullSemantic(m);
            modules.push(m);
        }
    }
    else if(isFile(path))
    {
        Module m = parseModule(path).module_;
        fullSemantic(m);
        modules.push(m);
    }
    return modules;
}

void checkNogcCoverage(Modules *modules)
{
    foreach(m; *modules)
    {
        m.nogcCoverageCheck(null);
    }
}


void main(string[] args)
{
    string path;
    Modules modules;
    string[] importPaths;

    path = args[1];

    for (int i = 2; i < args.length; i++)
        importPaths ~= args[i];

    initTool(importPaths);

    modules = prepareModules(path);

    checkNogcCoverage(&modules);

    deinitializeTool();
}
