#ifndef FRAME_H_
#define FRAME_H_

#include "ruby.h"

typedef struct frame_struct {
    char *file;
    int line;
    ID method_id;
    long binding_id;
} frame_t;

void initialize_frame(VALUE);
VALUE frame_new_from_tracepoint(VALUE);
VALUE frame_update_from_tracepoint(VALUE, VALUE);

#endif
