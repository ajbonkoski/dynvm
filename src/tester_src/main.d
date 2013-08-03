import std.stdio;
import std.path;
import std.file;
import std.regex;
import std.string;
import std.process;
import std.conv;

string TEST_DIR = "test";
auto BLACKLIST = [regex("#.*#"), regex(".*~")];
string ANS_EXT = ".ans";

class TesterError : Error { this(string s){ super(s); } }

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

  bool valid(){ return testfile != "" && ansfile != ""; }

  // impl by subclass
  string getRequiredTestfileExt();
  bool run();
}

class DynasmTest : Test
{
  immutable static string ext = ".da";
  this(string tf){ super(tf); }
  override string getRequiredTestfileExt(){ return ext; }

  override bool run()
  {
    string cmd = format("./dynvm -s %s/%s | diff %s/%s -",
                        TEST_DIR, testfile, TEST_DIR, ansfile);
    return executeShell(cmd).status == 0;
  }
}

class SluaTest : Test
{
  immutable static string ext = ".slua";
  this(string tf){ super(tf); }
  override string getRequiredTestfileExt(){ return ext; }
  override bool run() { assert(0, "unimplemented"); }
}

Test createTest(string name)
{
  // stringify func (required for the mixin case to compile)
  auto s(string t){ return "\""~t~"\""; }

  switch(name.extension) {
    case mixin(s(DynasmTest.ext)): return new DynasmTest(name);
    case mixin(s(SluaTest.ext)):   return new SluaTest(name);
    default:
      throw new TesterError("Failed to find test type for "~name);
  }
}

int[string]  test_ans_limbo;
Test[string] test_map;

void build_test_map()
{

  foreach(dirent; dirEntries(TEST_DIR, SpanMode.shallow)) {
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
      test_map[testname] = createTest(fname);
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

int run()
{
  build_test_map();

  writef("--------------------------------\n");
  writef("Running Tester with %d tests:\n", test_map.length);
  writef("--------------------------------\n");

  uint pass_count = 0;
  foreach(testname, test; test_map) {
    writef("Running '%s': ", testname, test.testfile, test.ansfile);
    bool passed = test.run();
    writef("%s\n", passed ? "PASSED" : "FAILED");
    if(passed) pass_count++;
  }

  double perc = 100.0*(to!double(pass_count) / to!double(test_map.length));
  writef("--------------------------------\n");
  writef("Pass Rate (%d/%d): %.2f\n", pass_count, test_map.length, perc);

  return pass_count == test_map.length ? 0 : 1;
}


int main()
{
  try { return run(); }
  catch(TesterError ex) { stderr.writeln("ERROR: ", ex.msg); }

  return 1;
}
