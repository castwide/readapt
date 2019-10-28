#ifndef FRAME_H_
#define FRAME_H_

#include "ruby.h"

typedef struct frame_struct {
    char *file;
    int line;
    VALUE binding;
} frame_t;

void initialize_frame(VALUE);
frame_t *frame_data_from_tracepoint(VALUE);
VALUE frame_new_from_data(frame_t *);
void frame_free(void *);

#endif
