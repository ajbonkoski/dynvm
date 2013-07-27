module common.common;

class IndentedWriter
{
  string _data;
  @property string data() { return _data; }
  uint width;
  uint indent_amt = 0;

  this(uint width)   { this.width = width; }
  void put(T)(T c) if(is(T : const(char)[]) || is(T : const(dchar)[]))
  { _data ~= c; }
  void put(T)(T c) if(is(T : const(char)) || is(T : const(dchar)))
  { _data ~= c; }

  void indent(uint n=1) { indent_amt += n; }
  void unindent(uint n=1) { indent_amt -= n; }

}
