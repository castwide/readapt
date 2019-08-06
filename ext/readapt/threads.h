typedef struct thread_reference_struct {
	long id;
	int depth;
	int cursor;
	VALUE prev_file;
	int prev_line;
	int stopped;
	ID control;
} thread_reference_t;

void initialize_threads();
VALUE thread_current_reference();
VALUE thread_reference(VALUE);
VALUE thread_add_reference(VALUE);
VALUE thread_delete_reference(VALUE);
thread_reference_t *thread_reference_pointer(VALUE);
void thread_pause();
void thread_reset();
