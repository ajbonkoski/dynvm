module dasm.literal;

enum LType { String, Int }
union LData
{
  string s;
  int i;
}

struct Literal
{
  LType type;
  LData data;
  alias data this;

  static Literal opCall(string s_)
  {
    Literal l;
    l.type = LType.String;
    l.s = s_;
    return l;
  }

  static Literal opCall(int i_)
  {
    Literal l;
    l.type = LType.Int;
    l.i = i_;
    return l;
  }

  size_t toHash() const
  {
    final switch(type)
    {
      case LType.String: return typeid(string).getHash(&s);
      case LType.Int:    return typeid(int).getHash(&i);
    }
  }

  bool opEquals(Literal other) const
  {
    if(this.type != other.type)
      return false;

    final switch(type)
    {
      case LType.String: return s == other.s;
      case LType.Int:    return i == other.i;
    }
  }

}