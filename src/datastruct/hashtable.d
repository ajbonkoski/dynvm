module datastruct.hashtable;
import std.exception;
import std.conv;

/* This alias sets up which impl is used */
alias
HashtableCustom
//HashtableDefault

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
public:

struct Pair(V)
{
  string key;
  V value;
}

class HashtableCustom(V) : Hashtable!V
{
  mixin(GetSetWrappers);

  static immutable SZ = 100;
  Pair!V[][SZ] table;

  override final ulong computeHash(string s)
  {
    return s[$-1].to!ulong % SZ;
  }

  override final V* get(string s, ulong hash)
  {
    auto data = table[hash];
    if(data.length == 1)
      return &data[0].value;

    foreach(pair; data) {
      if(pair.key == s)
        return &pair.value;
    }

    return null;
  }

  override final void set(string s, V v, ulong hash)
  {
    Pair!V p; p.key = s; p.value = v;
    table[hash] ~= p;
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
