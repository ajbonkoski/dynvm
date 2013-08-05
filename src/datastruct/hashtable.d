module datastruct.hashtable;
import std.exception;
import std.conv;

/* This alias sets up which impl is used */
alias
//HashtableCustom
HashtableDefault

DynvmHashTable;

/* The unified interface that should be expected */
private interface Hashtable(V)
{
  // Provided by impls
  ulong computeHash(string s);
  V* get(string s, ulong hash);
  void set(string s, V v, ulong hash);

  // These are simply wrappers - impl with the string below
  V* get(string s);
  void set(string s, V v);
}

private enum GetSetWrappers =
  "override final V* get(string s) { return get(s, computeHash(s)); }"~
  "override final void set(string s, V v) { return set(s, v, computeHash(s)); }";

/**************************************************************/
/**************************************************************/
/** NOTE: The implementations are intentionally private, so  **/
/**  another module won't create a naming dependency         **/
/**************************************************************/
/**************************************************************/
private:

class HashtableCustom(V) : Hashtable!V
{
  mixin(GetSetWrappers);

  static immutable SZ = 10000;
  V[SZ] table;

  override final ulong computeHash(string s)
  {
    s = s[5..$];

    ulong h = 0;
    foreach(c; s) {
      h += c.to!ulong;
      h <<= 7;
    }
    return h%SZ;

    // return
    //   (to!uint(s[$-3]) +
    //    to!uint(s[$-2]) +
    //    to!uint(s[$-1])) % SZ;
  }

  override final V* get(string s, ulong hash)
  {
    return &table[hash];
  }

  override final void set(string s, V v, ulong hash)
  {
    //import std.stdio;
    //writef("Adding %s to %d\n", s, hash);
    enforce(!table[hash]);
    table[hash] = v;
  }

}

class HashtableDefault(V) : Hashtable!V
{
  mixin(GetSetWrappers);
  V[string] table;

  override final ulong computeHash(string s)
  {
    return 0;
  }

  override final V* get(string s, ulong hash)
  {
    return s in table;
  }

  override final void set(string s, V v, ulong hash)
  {
    table[s] = v;
  }

}
