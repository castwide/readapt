#include "ruby.h"
#include "ruby/debug.h"
#include "threads.h"

static VALUE m_Monitor;
static VALUE c_Snapshot;

static VALUE tpLine;
static VALUE tpCall;
static VALUE tpReturn;
static VALUE tpThreadBegin;
static VALUE tpThreadEnd;
static VALUE debugProc;
static VALUE breakpoints;
static int knownBreakpoints;
static int monitorPaused;

static int match_line(VALUE next_file, int next_line, thread_reference_t *ptr)
{
	if (rb_str_equal(next_file, ptr->prev_file) && next_line == ptr->prev_line) {
		return 1;
	}
	return 0;
}

static int match_breakpoint(VALUE file, int line)
{
	VALUE bps, b;
	long len, i;

	bps = rb_funcall(breakpoints, rb_intern("for"), 1, file);
	len = rb_array_len(bps);
	for (i = 0; i < len; i++)
	{
		b = rb_ary_entry(bps, i);
		if (NUM2INT(rb_funcall(b, rb_intern("line"), 0)) == line)
		{
			return 1;
		}
	}
	return 0;
}

static int match_step(thread_reference_t *ptr)
{
	if (ptr->control == rb_intern("continue"))
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

static void
monitor_debug(VALUE file, int line, VALUE tracepoint, thread_reference_t *ptr, ID event)
{
	VALUE bind, bid, snapshot, result;

	// TODO: Preparing for multi-thread control
	// thread_pause();
	// ptr->control = rb_intern("pause");
	monitorPaused = 1;
	bind = rb_funcall(tracepoint, rb_intern("binding"), 0);
	bid = rb_funcall(bind, rb_intern("object_id"), 0);
	snapshot = rb_funcall(c_Snapshot, rb_intern("new"), 7,
		LONG2NUM(ptr->id),
		bid,
		file,
		INT2NUM(line),
		Qnil,
		ID2SYM(event),
		INT2NUM(ptr->depth)
	);
	rb_io_flush(rb_stdout);
	rb_io_flush(rb_stderr);
	rb_funcall(debugProc, rb_intern("call"), 1, snapshot);
	result = rb_funcall(snapshot, rb_intern("control"), 0);
	ptr->cursor = ptr->depth;
	ptr->control = SYM2ID(result);
	ptr->prev_file = file;
	ptr->prev_line = line;
	monitorPaused = 0;
}

static void
process_line_event(VALUE tracepoint, void *data)
{
	VALUE ref, tp_file;
	int tp_line;
	thread_reference_t *ptr;
	rb_trace_arg_t *tp;
	int threadPaused;

	ref = thread_current_reference();
	if (!RB_NIL_P(ref))
	{
		ptr = thread_reference_pointer(ref);
		//threadPaused = (monitorPaused || ptr->control == rb_intern("pause"));
		if (ptr->depth > 0)
		{
			threadPaused = (ptr->control == rb_intern("pause"));
			if (threadPaused || knownBreakpoints || ptr->control != rb_intern("continue"))
			{
				tp = rb_tracearg_from_tracepoint(tracepoint);
				tp_file = rb_tracearg_path(tp);
				tp_line = NUM2INT(rb_tracearg_lineno(tp));
				if (threadPaused || !match_line(tp_file, tp_line, ptr))
				{
					if (threadPaused || match_breakpoint(tp_file, tp_line) || match_step(ptr))
					{
						monitor_debug(tp_file, tp_line, tracepoint, ptr, rb_intern("breakpoint"));
					}
				}
			}
			else
			{
				ptr->prev_file = Qnil;
				ptr->prev_line = Qnil;
			}
		}
	}
}

static void
process_call_event(VALUE tracepoint, void *data)
{
	VALUE ref;
	thread_reference_t *ptr;

	ref = thread_current_reference();
	if (!RB_NIL_P(ref))
	{
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
	if (!RB_NIL_P(ref))
	{
		ptr = thread_reference_pointer(ref);
		ptr->depth--;
	}
}

static void
process_thread_begin_event(VALUE self, void *data)
{
	VALUE list, here, prev, ref;

	list = rb_funcall(rb_cThread, rb_intern("list"), 0);
	here = rb_ary_pop(list);
	if (!RB_NIL_P(here))
	{
		prev = rb_ary_pop(list);
		{
			if (!RB_NIL_P(prev))
			{
				ref = thread_reference(prev);
				if (!RB_NIL_P(ref))
				{
					thread_add_reference(here);
				}
			}
		}
	}
}

static void
process_thread_end_event(VALUE tracepoint, void *data)
{
	VALUE thr, ref;
	thread_reference_t *ptr;

	thr = rb_thread_current();
	ref = thread_reference(thr);
	if (!RB_NIL_P(ref))
	{
		ptr = thread_reference_pointer(ref);
		monitor_debug(ptr->prev_file, ptr->prev_line, tracepoint, ptr, rb_intern("thread_end"));
		thread_delete_reference(thr);
	}
}

static VALUE
monitor_enable_s(VALUE self)
{
	VALUE previous;

	if (rb_block_given_p()) {
		debugProc = rb_block_proc();
		rb_global_variable(&debugProc);
	} else {
		rb_raise(rb_eArgError, "must be called with a block");
	}
	thread_add_reference(rb_thread_current());

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
	
	return previous;
}

static VALUE
monitor_pause_s(VALUE self, VALUE id)
{
	VALUE ref;
	thread_reference_t *ptr;

	ref = thread_reference_id(id);
	if (!RB_NIL_P(ref))
	{
		ptr = thread_reference_pointer(ref);
		ptr->control = rb_intern("pause");
	}
}

static VALUE
monitor_know_breakpoints_s(VALUE self)
{
	knownBreakpoints = (rb_funcall(breakpoints, rb_intern("empty?"), 0) == Qfalse) ? 1 : 0;
	return Qnil;
}

void initialize_monitor(VALUE m_Readapt)
{
	m_Monitor = rb_define_module_under(m_Readapt, "Monitor");
	c_Snapshot = rb_define_class_under(m_Readapt, "Snapshot", rb_cObject);

	initialize_threads();

	rb_define_singleton_method(m_Monitor, "start", monitor_enable_s, 0);
	rb_define_singleton_method(m_Monitor, "stop", monitor_disable_s, 0);
	rb_define_singleton_method(m_Monitor, "know_breakpoints", monitor_know_breakpoints_s, 0);
	rb_define_singleton_method(m_Monitor, "pause", monitor_pause_s, 1);

	tpLine = rb_tracepoint_new(Qnil, RUBY_EVENT_LINE, process_line_event, NULL);
	tpCall = rb_tracepoint_new(Qnil, RUBY_EVENT_CALL | RUBY_EVENT_B_CALL | RUBY_EVENT_CLASS, process_call_event, NULL);
	tpReturn = rb_tracepoint_new(Qnil, RUBY_EVENT_RETURN | RUBY_EVENT_B_RETURN | RUBY_EVENT_END, process_return_event, NULL);
	tpThreadBegin = rb_tracepoint_new(Qnil, RUBY_EVENT_THREAD_BEGIN, process_thread_begin_event, NULL);
	tpThreadEnd = rb_tracepoint_new(Qnil, RUBY_EVENT_THREAD_END, process_thread_end_event, NULL);
	debugProc = Qnil;
	breakpoints = rb_funcall(m_Monitor, rb_intern("breakpoints"), 0);
	knownBreakpoints = 0;
	monitorPaused = 0;

	// Avoid garbage collection
	rb_global_variable(&tpLine);
	rb_global_variable(&tpCall);
	rb_global_variable(&tpReturn);
	rb_global_variable(&tpThreadBegin);
	rb_global_variable(&tpThreadEnd);
}
