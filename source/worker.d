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

    bool printTrusted;
    bool printSystem;

    this(Scope* sc, bool printTrusted, bool printSystem)
    {
        this.sc = sc;
        this.printTrusted = printTrusted;
        this.printSystem = printSystem;
    }


    override void visit(FuncDeclaration fd)
    {
      if(fd.isTrusted && printTrusted) {
        printFunction(fd);
      }

      if(isSystem(fd) && printSystem) {
        printFunction(fd);
      }
    }

    bool isSystem(FuncDeclaration fd) {
      return !fd.isSafe && !fd.isTrusted;
    }

    void printFunction(FuncDeclaration fd) {
      if(fd.getModule() is null) {
        writeln(fd.toString());
      } else {
        writeln(fd.getModule().toString()~"."~fd.toString());
      }
    }
}

void nogcCoverageCheck(Dsymbol dsym, Scope* sc, bool printTrusted, bool printSystem)
{
    Module m = cast(Module)dsym;
    scope v = new NogcCoverageVisitor(sc, printTrusted, printSystem);
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

void checkNogcCoverage(bool printTrusted, bool printSystem, Modules *modules)
{
    foreach(m; *modules)
    {
        m.nogcCoverageCheck(null, printTrusted, printSystem);
    }
}


void main(string[] args)
{
    string path;
    string securityLevel;
    Modules modules;
    string[] importPaths;
    bool printTrusted;
    bool printSystem;

    securityLevel = args[1];
    if(securityLevel == "-trusted") {
      printTrusted = true;
      printSystem = false;
    }else if(securityLevel == "-system") {
      printTrusted = false;
      printSystem = true;
    } else if(securityLevel == "-non-safe") {
      printTrusted = true;
      printSystem = true;
    } else {
      writeln("UNEXPECTED securityLevel "~securityLevel);
      return;
    }

    path = args[2];
    for (int i = 3; i < args.length; i++)
        importPaths ~= args[i];

    initTool(importPaths);

    modules = prepareModules(path);

    checkNogcCoverage(printTrusted, printSystem, &modules);

    deinitializeTool();
}
