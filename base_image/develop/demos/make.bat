echo "building " $0;
/develop/jkl incdir=/develop/lib $0 out.asm;
/develop/xrasm incdir=/develop/lib out.asm out.o;
/develop/xrlink link out.fxf out.o /develop/lib/fox.lib;
del out.o;
del out.asm;
echo "done! built out.fxf";
exit;
