#ifndef THREADS_H_
#define THREADS_H_

#include "ruby.h"
#include "frame.h"
#include "stack.h"

typedef struct thread_reference_struct {
	long id;
	int cursor;
	int depth;
	ID control;
	stack_t *frames;
	// stack_t *calls;
} thread_reference_t;

void initialize_threads(VALUE);
VALUE thread_current_reference();
VALUE thread_reference(VALUE);
VALUE thread_reference_id(VALUE);
VALUE thread_add_reference(VALUE);
VALUE thread_delete_reference(VALUE);
// thread_reference_t *thread_reference_update_frames(VALUE ref, VALUE tracepoint);
void thread_reference_push_frame(thread_reference_t *, VALUE);
// void thread_reference_push_stack(VALUE ref);
// void thread_reference_pop_stack(VALUE ref);
thread_reference_t *thread_reference_pointer(VALUE);
void thread_reference_build_frames(thread_reference_t *);
void thread_reference_clear_frames(thread_reference_t *);
void thread_pause();
void thread_clear();

#endif
