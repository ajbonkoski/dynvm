module vm.dyn_obj.dyn_tag;
import vm.dyn_obj.core;

/******************************************************************/
/*********************** Tagging helpers **************************/
/******************************************************************/

DynObject  Dyn_tag_obj(DynObject obj) { return cast(DynObject)(cast(long)obj | 1); }
DynObject  Dyn_untag_obj(DynObject obj) { return cast(DynObject)(cast(long)obj & ~1); }

DynObject  Dyn_tag_int(long obj) { return cast(DynObject)(obj<<1); }
long       Dyn_untag_int(DynObject obj) { return cast(long)obj >> 1; }

bool       Dyn_tag_is_int(DynObject obj) { return (cast(long)obj & 1) == 0; }
bool       Dyn_tag_is_obj(DynObject obj) { return (cast(long)obj & 1) != 0; }

