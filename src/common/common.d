module common.common;

class IndentedWriter
{
  string _data;
  @property string data() { return _data; }
  uint width;
  uint indent_amt = 0;
  bool newline_started = false;

  this(uint width)   { this.width = width; }

  void add_indention()
  {
    foreach(i; 0..width*indent_amt)
      _data ~= ' ';
  }

  void put(T)(T s) if(is(T : const(char)[]) || is(T : const(dchar)[]))
  {
    foreach(dchar c; s)
      put(c);
  }

  void put(T)(T c) if(is(T : const(char)) || is(T : const(dchar)))
  {
      if(newline_started) {
        add_indention();
        newline_started = false;
      }

      if(c == '\n')
        newline_started = true;

      _data ~= c;
  }

  void indent(uint n=1) { indent_amt += n; }
  void unindent(uint n=1) { indent_amt -= n; }

}
