#include "ruby.h"
#include "ruby/debug.h"
#include "threads.h"
#include "normalize.h"
#include "breakpoints.h"

static VALUE readapt;
static VALUE m_Monitor;
static VALUE c_Snapshot;

static VALUE readapt;
static VALUE tpLine;
static VALUE tpCall;
static VALUE tpReturn;
static VALUE tpThreadBegin;
static VALUE tpThreadEnd;
static VALUE debugProc;
static int firstLineEvent = 0;
static char *entryFile;

static ID id_continue;
static ID id_pause;
static ID id_entry;

static int match_step(thread_reference_t *ptr)
{
	if (ptr->control == id_continue)
	{
		return 0;
	}
	else if (ptr->control == rb_intern("next") && ptr->cursor >= ptr->depth)
	{
		return 1;
	}
	else if (ptr->control == rb_intern("step_in") && ptr->cursor < ptr->depth)
	{
		return 1;
	}
	else if (ptr->control == rb_intern("step_out") && ptr->cursor > ptr->depth)
	{
		return 1;
	}
	return 0;
}

static ID
monitor_debug(const char *file, const long line, VALUE tracepoint, thread_reference_t *ptr, ID event)
{
	VALUE snapshot, result;

	// thread_reference_build_frames(ptr);
	snapshot = rb_funcall(c_Snapshot, rb_intern("new"), 4,
		LONG2NUM(ptr->id),
		rb_str_new_cstr(file),
		INT2NUM(line),
		ID2SYM(event),
	);
	rb_io_flush(rb_stdout);
	rb_io_flush(rb_stderr);
	rb_funcall(debugProc, rb_intern("call"), 1, snapshot);
	result = SYM2ID(rb_funcall(snapshot, rb_intern("control"), 0));
	if (event != rb_intern("initialize"))
	{
		ptr->cursor = ptr->depth;
		ptr->control = result;
	}
	// thread_reference_clear_frames(ptr);
	return result;
}

static void
process_line_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	thread_reference_t *ptr;
	rb_trace_arg_t *arg;
	int threadPaused;
	ID dapEvent;
	// frame_t *frame;
	VALUE tmp;
	char *tp_file;
	long tp_line;

	ref = thread_current_reference();
	if (ref != Qnil)
	{
		ptr = thread_reference_pointer(ref);
		threadPaused = (ptr->control == id_pause);
		arg = rb_tracearg_from_tracepoint(tracepoint);
		tmp = rb_tracearg_path(arg);
		tp_file = normalize_path_new_cstr(StringValueCStr(tmp));
		tmp = rb_tracearg_lineno(arg);
		tp_line = NUM2INT(tmp);

		if (firstLineEvent && ptr->control == id_continue && breakpoints_files() == 0)
		{
			return;
		}
		
		dapEvent = id_continue;
		if (!firstLineEvent)
		{
			if (strcmp(tp_file, entryFile) == 0)
			{
				firstLineEvent = 1;
				ptr->control = rb_intern("entry");
				process_line_event(tracepoint, data);
			}
		}
		else if (threadPaused)
		{
			dapEvent = id_pause;
		}
		else if (match_step(ptr))
		{
			dapEvent = rb_intern("step");
		}
		else if (breakpoints_match(tp_file, tp_line))
		{
			dapEvent = rb_intern("breakpoint");
		}
		else if (ptr->control == id_entry)
		{
			dapEvent = id_entry;
		}

		if (dapEvent != id_continue)
		{
			monitor_debug(tp_file, tp_line, tracepoint, ptr, dapEvent);
		}

		free(tp_file);
	}
}

static void
process_call_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	thread_reference_t *ptr;

	ref = thread_current_reference();
	if (ref != Qnil)
	{
		// thread_reference_push_stack(ref);
		ptr = thread_reference_pointer(ref);
		ptr->depth++;
	}
}

static void
process_return_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	thread_reference_t *ptr;
	
	ref = thread_current_reference();
	if (ref != Qnil)
	{
		// thread_reference_pop_stack(ref);
		ptr = thread_reference_pointer(ref);
		ptr->depth--;
	}
}

static void
process_thread_begin_event(VALUE tracepoint, void *data)
{
	VALUE list, here, ref;
	thread_reference_t *ptr;

	list = rb_funcall(rb_cThread, rb_intern("list"), 0);
	here = rb_ary_pop(list);
	if (here != Qnil)
	{
		ref = thread_add_reference(here);
		// thread_reference_push_frame(ref, tracepoint);
		ptr = thread_reference_pointer(ref);
		// monitor_debug(
		// 	"",
		// 	0,
		// 	tracepoint,
		// 	ptr,
		// 	rb_intern("thread_begin")
		// );
	}
}

static void
process_thread_end_event(VALUE tracepoint, void *data)
{
	VALUE thr, ref;
	thread_reference_t *ptr;

	thr = rb_thread_current();
	if (thr != Qnil)
	{
		ref = thread_reference(thr);
		if (ref != Qnil)
		{
			ptr = thread_reference_pointer(ref);
			// monitor_debug("", 0, tracepoint, ptr, rb_intern("thread_end"));
			thread_delete_reference(thr);
		}
	}
}

static VALUE
monitor_enable_s(VALUE self, VALUE file)
{
	VALUE previous, ref;
	thread_reference_t *ptr;

	if (rb_block_given_p()) {
		debugProc = rb_block_proc();
		rb_global_variable(&debugProc);
	} else {
		rb_raise(rb_eArgError, "must be called with a block");
	}

	if (file == Qnil)
	{
		entryFile = NULL;
		firstLineEvent = 1;
	}
	else
	{
		entryFile = normalize_path_new_cstr(StringValueCStr(file));
		firstLineEvent = 0;
	}

	ref = thread_add_reference(rb_thread_current());
	ptr = thread_reference_pointer(ref);
	monitor_debug(
		"",
		0,
		Qnil,
		ptr,
		rb_intern("thread_begin")
	);

	previous = rb_tracepoint_enabled_p(tpLine);
	rb_tracepoint_enable(tpLine);
	rb_tracepoint_enable(tpCall);
	rb_tracepoint_enable(tpReturn);
	rb_tracepoint_enable(tpThreadBegin);
	rb_tracepoint_enable(tpThreadEnd);
	return previous;
}

static VALUE
monitor_disable_s(VALUE self)
{
	VALUE previous;

	previous = rb_tracepoint_enabled_p(tpLine);
	rb_tracepoint_disable(tpLine);
	rb_tracepoint_disable(tpCall);
	rb_tracepoint_disable(tpReturn);
	rb_tracepoint_disable(tpThreadBegin);
	rb_tracepoint_disable(tpThreadEnd);

	free(entryFile);
	entryFile = NULL;
	thread_clear();

	return previous;
}

static VALUE
monitor_pause_s(VALUE self, VALUE id)
{
	VALUE ref;
	thread_reference_t *ptr;

	ref = thread_reference_id(id);
	if (ref != Qnil)
	{
		ptr = thread_reference_pointer(ref);
		ptr->control = rb_intern("pause");
	}
	return Qnil;
}

void initialize_monitor(VALUE m_Readapt)
{
	readapt = m_Readapt;
	m_Monitor = rb_define_module_under(m_Readapt, "Monitor");
	c_Snapshot = rb_define_class_under(m_Readapt, "Snapshot", rb_cObject);

	initialize_threads(m_Readapt);

	rb_define_singleton_method(m_Monitor, "start", monitor_enable_s, 1);
	rb_define_singleton_method(m_Monitor, "stop", monitor_disable_s, 0);
	rb_define_singleton_method(m_Monitor, "pause", monitor_pause_s, 1);

	tpLine = rb_tracepoint_new(Qnil, RUBY_EVENT_LINE, process_line_event, NULL);
	tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL | RUBY_EVENT_B_CALL | RUBY_EVENT_CLASS | RUBY_EVENT_C_CALL, process_call_event, NULL);
	tpReturn = rb_tracepoint_new(Qnil, RUBY_EVENT_RETURN | RUBY_EVENT_B_RETURN | RUBY_EVENT_END | RUBY_EVENT_C_RETURN, process_return_event, NULL);
	tpThreadBegin = rb_tracepoint_new(Qnil, RUBY_EVENT_THREAD_BEGIN, process_thread_begin_event, NULL);
	tpThreadEnd = rb_tracepoint_new(Qnil, RUBY_EVENT_THREAD_END, process_thread_end_event, NULL);
	debugProc = Qnil;

	id_continue = rb_intern("continue");
	id_pause = rb_intern("pause");
	id_entry = rb_intern("entry");

	// Avoid garbage collection
	rb_global_variable(&tpLine);
	rb_global_variable(&tpCall);
	rb_global_variable(&tpReturn);
	rb_global_variable(&tpThreadBegin);
	rb_global_variable(&tpThreadEnd);
}
