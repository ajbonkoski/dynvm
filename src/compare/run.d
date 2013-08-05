#!/usr/local/bin/rdmd --preserve-path

import std.stdio;
import std.path;
import std.file;
import std.exception;
import std.string;
import std.process;
import std.conv;
import std.datetime;

enum EXEC_MASK = 1<<6;
enum SEPARATOR_SIZE = 55;
enum LINE_SIZE = SEPARATOR_SIZE-20;

// a nice python-style 'c'*5 string utility
auto s(char c, ulong times) { char[] s; s.length = times; foreach(i; 0..times) s[i] = c; return s;}
void write_separator(char c) { writeln(s(c, SEPARATOR_SIZE)); }

void write_output_line(A, B)(A a_, B b_)
{
  auto a = a_.to!string;
  auto b = b_.to!string;
  writef("  %s%s%s\n", a, s(' ', LINE_SIZE-a.length), b);
}

void build_dir(string dir)
{
  string cmd = format("make -C %s", dir);
  auto res = executeShell(cmd);
  assert(res.status == 0, "Build failed");
}

void execute(string cmd)
{
  StopWatch sw;

  sw.start();
  auto res = executeShell(cmd);
  sw.stop();

  if(res.status == 0)
    write_output_line(cmd, sw.peek().to!("seconds", double));
  else
    write_output_line(cmd, "FAILED");
}

void main(string[] args)
{
  enforce(args.length >= 3);
  auto dir = buildNormalizedPath(args[0].dirName, args[1]);
  auto subargs = join(args[2..$]);
  writeln(dir);

  writef("Building %s...\n", dir);
  build_dir(dir);

  write_separator('=');
  write_output_line("Language", "Time");
  write_separator('=');

  foreach(dirent; dirEntries(dir, SpanMode.shallow)) {
    if(dirent.attributes & EXEC_MASK) {
      execute(format("./%s %s", dirent.name, subargs));
    }
  }


  // I Hate this being here, but rdmd doesn't cleanup properly, so here it is...
  remove(args[0]);   // delete self, so its not accidently called
  remove(buildNormalizedPath(args[0].dirName, "rdmd.deps"));

}
