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

static void tracepoint_info(VALUE tracepoint)
{
	VALUE sp = rb_str_new_cstr(" ");

	rb_funcall(rb_stderr, rb_intern("print"), 2, rb_funcall(tracepoint, rb_intern("path"), 0), sp);
	rb_funcall(rb_stderr, rb_intern("print"), 2, rb_funcall(tracepoint, rb_intern("lineno"), 0), sp);
	rb_funcall(rb_stderr, rb_intern("puts"), 1, rb_funcall(tracepoint, rb_intern("event"), 0));
}

static int match_step(thread_reference_t *ptr)
{
	if (ptr->control == id_continue)
	{
		return 0;
	}
	else if (ptr->control == rb_intern("next") && ptr->cursor >= ptr->frames->size)
	{
		return 1;
	}
	else if (ptr->control == rb_intern("step_in") && ptr->cursor < ptr->frames->size)
	{
		return 1;
	}
	else if (ptr->control == rb_intern("step_out") && ptr->cursor > ptr->frames->size)
	{
		return 1;
	}
	return 0;
}

static ID
monitor_debug(const char *file, const long line, VALUE tracepoint, thread_reference_t *ptr, ID event)
{
	VALUE bind, bid, snapshot, result;

	bind = rb_funcall(tracepoint, rb_intern("binding"), 0);
	bid = rb_funcall(bind, rb_intern("object_id"), 0);
	snapshot = rb_funcall(c_Snapshot, rb_intern("new"), 7,
		LONG2NUM(ptr->id),
		bid,
		rb_str_new_cstr(file),
		INT2NUM(line),
		Qnil,
		ID2SYM(event),
		INT2NUM(ptr->frames->size)
	);
	rb_io_flush(rb_stdout);
	rb_io_flush(rb_stderr);
	rb_funcall(debugProc, rb_intern("call"), 1, snapshot);
	result = SYM2ID(rb_funcall(snapshot, rb_intern("control"), 0));
	if (event != rb_intern("initialize"))
	{
		ptr->cursor = ptr->frames->size;
		ptr->control = result;
	}
	return result;
}

static void
process_line_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	thread_reference_t *ptr;
	int threadPaused;
	ID dapEvent;
	frame_t *frame;

	ref = thread_current_reference();
	if (ref != Qnil)
	{
		tracepoint_info(tracepoint);

		ptr = thread_reference_update_frames(ref, tracepoint);
		frame = stack_peek(ptr->frames);
		threadPaused = (ptr->control == id_pause);
		if (firstLineEvent && ptr->control == id_continue && breakpoints_files() == 0)
		{
			return;
		}
		dapEvent = id_continue;
		if (!firstLineEvent)
		{
			if (strcmp(frame->file, entryFile) == 0)
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
		else if (breakpoints_match(frame->file, frame->line))
		{
			dapEvent = rb_intern("breakpoint");
		}
		else if (ptr->control == id_entry)
		{
			dapEvent = id_entry;
		}

		if (dapEvent != id_continue)
		{
			monitor_debug(frame->file, frame->line, tracepoint, ptr, dapEvent);
		}
	}
}

static void
process_call_event(VALUE tracepoint, void *data)
{
	VALUE ref;

	ref = thread_current_reference();
	if (ref != Qnil)
	{
		tracepoint_info(tracepoint);
		thread_reference_push_stack(ref);
	}
}

static void
process_return_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	
	ref = thread_current_reference();
	if (ref != Qnil)
	{
		tracepoint_info(tracepoint);
		thread_reference_pop_stack(ref);
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
		monitor_debug(
			"",
			0,
			tracepoint,
			ptr,
			rb_intern("thread_begin")
		);
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
			monitor_debug("", 0, tracepoint, ptr, rb_intern("thread_end"));
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
	// tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL, process_call_event, NULL);
	// tpReturn = rb_tracepoint_new(Qnil, RUBY_EVENT_RETURN | RUBY_EVENT_NONE, process_return_event, NULL);
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
