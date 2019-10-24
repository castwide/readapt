#ifndef THREADS_H_
#define THREADS_H_

#include "ruby.h"
#include "frame.h"

typedef struct thread_reference_struct {
	long id;
	int depth;
	int capacity;
	int cursor;
	ID control;
	frame_t **frames;
} thread_reference_t;

void initialize_threads(VALUE);
VALUE thread_current_reference();
VALUE thread_reference(VALUE);
VALUE thread_reference_id(VALUE);
VALUE thread_add_reference(VALUE);
VALUE thread_delete_reference(VALUE);
void thread_reference_push_frame(VALUE ref, VALUE tracepoint);
frame_t *thread_reference_update_frame(VALUE ref, VALUE tracepoint);
void thread_reference_pop_frame(VALUE ref);
thread_reference_t *thread_reference_pointer(VALUE);
void thread_pause();
void thread_clear();

#endif
