#!/usr/local/bin/rdmd --preserve-path
import std.stdio;
import std.path;
import std.file;
import std.regex;
import std.string;
import std.process;
import std.conv;
import std.getopt;
import std.datetime;

bool DEBUG = false;

string ROOT_DIR = "";
string TEST_DIR = "testsuite";
auto DYNVM_BIN_OPT = ["dynvm", "dynvm-debug", "dynvm-profile"];
string DYNVM; // this will be init to one of the binaries above
auto BLACKLIST = [regex("#.*#"), regex(".*~")];
string ANS_EXT = ".ans";
uint SEPARATOR_SIZE = 55;

string PASSED = "\033[32mPASSED\033[0m";
string FAILED = "\033[31mFAILED\033[0m";
string BUILD_FAILED = "\033[31mBUILD FAILED\033[0m";

class TesterError : Error { this(string s){ super(s); } }

void select_binaries()
{
  // find DYNVM
  foreach(dynvm; DYNVM_BIN_OPT) {
    try {
      if(isFile(ROOT_DIR~"/bin/"~dynvm)) {
        DYNVM = dynvm;
        return;
      }
    }catch(FileException ex){}
  }

  throw new TesterError("Failed to find dynvm binary");
}

abstract class Test
{
  this(string tf) { testfile = tf; }

  string _testfile;
  @property auto testfile(){ return _testfile; }
  @property void testfile(string tf) {
    assert(tf.extension == getRequiredTestfileExt());
    _testfile = tf;
  }

  string _ansfile;
  @property auto ansfile(){ return _ansfile; }
  @property void ansfile(string af) {
    assert(af.extension == ANS_EXT);
    _ansfile = af;
  }

  bool success;
  string output;

  bool valid(){ return testfile != "" && ansfile != ""; }

  // by default, nothing to build
  bool build() { return true; }

  // impl by subclass
  string getRequiredTestfileExt();
  bool run();
}

class HlasmTest : Test
{
  immutable static string ext = ".da";
  bool use_jit = false;
  this(string tf, bool use_jit=false){ super(tf); this.use_jit = use_jit; }
  override string getRequiredTestfileExt(){ return ext; }

  override bool run()
  {
    string cmd = format("%s/bin/%s %s -s %s/%s/%s | diff %s/%s/%s -",
                        ROOT_DIR, DYNVM, use_jit ? "-j" : "",
                        ROOT_DIR, TEST_DIR, testfile,
                        ROOT_DIR, TEST_DIR, ansfile);
    auto res = executeShell(cmd);
    success = (res.status == 0);
    output = res.output;

    return success;
  }
}

class SluaTest : Test
{
  immutable static string ext = ".slua";
  bool use_jit = false;
  this(string tf, bool use_jit=false){ super(tf); this.use_jit = use_jit; }
  override string getRequiredTestfileExt(){ return ext; }

  string CMD;
  override bool build()
  {
    string cmd = format("cat %s/%s/%s | %s/bin/slua -", ROOT_DIR, TEST_DIR, testfile, ROOT_DIR);
    if(DEBUG) cmd.writeln;
    auto res = executeShell(cmd);
    if(res.status != 0 || res.output == "")
      return false;
    CMD = format("echo '%s' | %s/bin/%s %s -s - | diff %s/%s/%s -",
                 res.output,
                 ROOT_DIR, DYNVM, use_jit ? "-j" : "",
                 ROOT_DIR, TEST_DIR, ansfile);
    if(DEBUG) CMD.writeln;
    return true;
  }

  override bool run()
  {
    assert(CMD != "");
    auto res = executeShell(CMD);
    success = (res.status == 0);
    output = res.output;

    return success;
  }
}

Test createTest(string name, bool use_jit=false)
{
  // stringify func (required for the mixin case to compile)
  auto s(string t){ return "\""~t~"\""; }

  switch(name.extension) {
    case mixin(s(HlasmTest.ext)):  return new HlasmTest(name, use_jit);
    case mixin(s(SluaTest.ext)):   return new SluaTest(name, use_jit);
    default:
      throw new TesterError("Failed to find test type for "~name);
  }
}

int[string]  test_ans_limbo;
Test[string] test_map;

void build_test_map(bool use_jit)
{

  auto dir = buildNormalizedPath(ROOT_DIR, TEST_DIR);
  foreach(dirent; dirEntries(dir, SpanMode.shallow)) {
    auto fname = dirent.name.baseName;

    // filter out the junk
    if(fname[0] == '.') continue;
    bool good = true;
    foreach(r; BLACKLIST) {
      if(match(fname, r)) {
        good = false;
        break;
      }
    }
    if(!good) continue;

    auto testname = fname.stripExtension;

    // ans file?
    if(fname.extension == ANS_EXT) {
      if(testname in test_ans_limbo)
        throw new TesterError(format("Ans file already exists for test '%s' for '%s'", testname, fname));
      test_ans_limbo[testname] = 1;
    }

    // an actual test file?
    else {
      if(testname in test_map)
        throw new TesterError(format("Test '%s' already exists for '%s'", testname, fname));
      test_map[testname] = createTest(fname, use_jit);
    }
  }


  // fill all ans files, and check for remainders
  foreach(testname; test_ans_limbo.byKey) {
    if(testname !in test_map)
      throw new TesterError(format("Test '%s' doesn't exist for ans file '%s'", testname, testname~ANS_EXT));
    test_map[testname].ansfile = testname~ANS_EXT;
  }

  // verify that all tests are valid
  foreach(testname, test; test_map) {
    if(!test.valid)
      throw new TesterError(format("Test '%s' is not valid. It likely is missing a %s file", testname, ANS_EXT));
  }

}

int run(bool use_jit)
{
  select_binaries();
  build_test_map(use_jit);

  // a nice python-style 'c'*5 string utility
  auto s(char c, uint times) { char[] s; s.length = times; foreach(i; 0..times) s[i] = c; return s;}
  void write_separator(char c) { writeln(s(c, SEPARATOR_SIZE)); }

  write_separator('=');
  writef("Running Tester with %d tests using '%s'%s:\n", test_map.length, DYNVM, use_jit ? "in JIT mode" : "");
  write_separator('=');
  writef("\n");

  uint pass_count = 0;
  StopWatch sw;
  foreach(testname; test_map.keys.sort) {

    auto test = test_map[testname];
    writef("%-30s ", testname);
    stdout.flush();

    if(!test.build()) {
      writeln(BUILD_FAILED);
      continue;
    }

    sw.reset();
    sw.start();
    bool passed = test.run();
    sw.stop();

    writef("%.3f             %s\n",
           sw.peek().to!("seconds", double),
           passed ? PASSED : FAILED);

    if(passed) {
      pass_count++;
    } else if(SHOW_OUTPUT_ON_FAILURE){
      write_separator('-');
      writef("%s\n", test.output);
    }
  }

  double perc = 100.0*(to!double(pass_count) / to!double(test_map.length));
  writef("\n");
  write_separator('=');
  writef("Pass Rate (%d/%d): %.2f\n", pass_count, test_map.length, perc);

  return pass_count == test_map.length ? 0 : 1;
}

bool SHOW_OUTPUT_ON_FAILURE = false;

int main(string[] args)
{
  bool silent  = false;
  bool verbose = false;
  bool use_jit = false;

  getopt(args,
         "silent|s",  &silent,
         "verbose|v", &verbose,
         "use-jit|j", &use_jit);

  if(silent && verbose) {
    stderr.writeln("Error: --silent and --verbose cannot be used at the same time!");
    return 1;
  }

  if(silent)  SHOW_OUTPUT_ON_FAILURE = false;
  if(verbose) SHOW_OUTPUT_ON_FAILURE = true;


  ROOT_DIR = args[0].dirName.absolutePath.buildNormalizedPath("..");
  try { return run(use_jit); }
  catch(TesterError ex) { stderr.writeln("ERROR: ", ex.msg); }

  return 1;
}
