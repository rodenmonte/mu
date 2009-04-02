#include <smop/native.h>
void smop_native_init(SMOP__Object* interpreter) {
  smop_nagc_ri_init();
  smop_native_int_init(interpreter);
}
 
void smop_native_destr(SMOP__Object* interpreter) {
  smop_native_int_destr(interpreter);
  smop_nagc_ri_destr();
}