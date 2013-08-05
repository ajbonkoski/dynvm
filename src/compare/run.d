#!/usr/local/bin/rdmd --preserve-path

import std.stdio;
import std.path;
import std.file;
import std.exception;
import std.string;
import std.process;
import std.conv;
import std.datetime;
import std.c.stdlib;
import std.regex;

enum EXEC_MASK = 1<<6;
enum SEPARATOR_SIZE = 55;
enum LINE_SIZE = SEPARATOR_SIZE-20;
enum REQUIRED_FILES = ["argv", "ans", "Makefile"];
auto BLACKLIST = [regex("#.*#"), regex(".*~")];
enum LANGUAGE_MAP = [
  "":          "C Language",
  "java.run":  "Java",
  "py":        "CPython",
  "js":        "Javascript V8"
];

string extToLang(string s)
{
  try {
    return LANGUAGE_MAP[s];
  } catch(RangeError err) {
    stderr.writef("Error: failed to lookup extention for %s\n", s);
    exit(1);
  }

  // dead code, to apease the compiler
  return "";
}

bool isBlacklisted(string name)
{
  foreach(r; BLACKLIST)
    if(name.match(r))
      return true;
  return false;
}

// a nice python-style 'c'*5 string utility
auto s(char c, ulong times) { char[] s; s.length = times; foreach(i; 0..times) s[i] = c; return s;}
void write_separator(char c) { writeln(s(c, SEPARATOR_SIZE)); }

void write_output_line(A, B)(A a_, B b_)
{
  auto a = a_.to!string;
  auto b = b_.to!string;
  writef("  %s%s%s\n", a, s(' ', LINE_SIZE-a.length), b);
}

bool GOOD = true;
void require_dir(string dir, void delegate() f){ require_file(dir, "", f); }
void require_file(string dir, string file, void delegate() f)
{ if(!buildPath(dir, file).exists) { GOOD = false; f(); } }

void verify_dir(string dir)
{
  require_dir(dir, {
      stderr.writef("Error: program suite '%s' doesn't exist\n", dir);
      exit(1);
  });

  foreach(file; REQUIRED_FILES) require_file(dir, file, {
      stderr.write("Error: expected to find '%s' for program suite '%s'\n", file, dir);
  });

  if(!GOOD) exit(1);
}

void build_dir(string dir)
{
  string cmd = format("make -C %s", dir);
  auto res = executeShell(cmd);
  assert(res.status == 0, "Build failed");
}

void execute(string name, string argv)
{
  StopWatch sw;
  auto cmd = format("%s %s", name, argv);
  auto lang = name.baseName.split(".")[1..$].join(".").extToLang;

  sw.start();
  auto res = executeShell(cmd);
  sw.stop();

  if(res.status == 0) {
    double dt = sw.peek().to!("seconds", double);
    write_output_line(lang, format("%.3f", dt));
  } else {
    write_output_line(lang, "FAILED");
  }
}

int main(string[] args)
{
  scope(exit) doCleanup(args);

  if(args.length != 2) {
    stderr.writef("usage: %s <name>\n", args[0]);
    return 1;
  }

  auto dir = buildPath(args[0].dirName, args[1]);
  dir.verify_dir();
  auto subargs = buildPath(dir, "argv").readText.chomp;
  build_dir(dir);

  write_separator('=');
  write_output_line("Language", "Time (in sec)");
  write_separator('=');

  foreach(dirent; dirEntries(dir, SpanMode.shallow)) {
    if(dirent.baseName.isBlacklisted) continue;
    if(dirent.attributes & EXEC_MASK)
      execute(dirent.name, subargs);

  }

  return 0;
}

// I Hate this being here, but rdmd doesn't cleanup properly, so here it is...
void doCleanup(string[] args)
{
  remove(args[0]);   // delete self, so its not accidently called
  remove(buildPath(args[0].dirName, "rdmd.deps"));
}
