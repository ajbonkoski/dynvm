module datastruct.hashtable;
import std.exception;
import std.conv;

class DynvmHashTable(V)
{
  static immutable SZ = 200;
  V[SZ] table;

  this()
  {
    foreach (i; 0..SZ)
      table[i] = null;
  }

  uint computeHash(string s)
  {
    return
      (to!uint(s[$-3]) +
      to!uint(s[$-2]) +
       to!uint(s[$-1])) % SZ;
  }

  V* get(string s)
  {
    return get(s, computeHash(s));
  }

  V* get(string s, uint hash)
  {
    return &table[hash];
  }

  void set(string s, V v)
  {
    set(s, v, computeHash(s));
  }

  void set(string s, V v, uint hash)
  {
    //enforce(table[hash] is null);
    table[hash] = v;
  }

}
