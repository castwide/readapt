#include "ruby.h"
#include "ruby/debug.h"
#include "threads.h"
#include "frame.h"

static VALUE c_Thread;
static VALUE threads;

void thread_reference_free(void* data)
{
	free(data);
}

size_t thread_reference_size(const void* data)
{
	return sizeof(thread_reference_t);
}

static const rb_data_type_t thread_reference_type = {
	.wrap_struct_name = "thread_reference",
	.function = {
		.dmark = NULL,
		.dfree = thread_reference_free,
		.dsize = thread_reference_size,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

VALUE thread_reference_new(VALUE thr)
{
	thread_reference_t *data = malloc(sizeof(thread_reference_t));
	VALUE obj = TypedData_Make_Struct(c_Thread, thread_reference_t, &thread_reference_type, data);
	data->id = NUM2LONG(rb_funcall(thr, rb_intern("object_id"), 0));
	data->depth = 0;
	data->cursor = 0;
	data->control = rb_intern("continue");
	return obj;
}

thread_reference_t *thread_reference_pointer(VALUE ref)
{
	thread_reference_t *ptr;
    TypedData_Get_Struct(ref, thread_reference_t, &thread_reference_type, ptr);
    return ptr;
}

VALUE thread_current_reference()
{
	return thread_reference(rb_thread_current());
}

VALUE thread_reference(VALUE thr)
{
	return rb_hash_aref(threads, rb_obj_id(thr));
}

VALUE thread_reference_id(VALUE id)
{
	return rb_hash_aref(threads, id);
}

VALUE thread_add_reference(VALUE thr)
{
	VALUE ref;

	ref = thread_reference_new(thr);
	rb_hash_aset(threads, rb_obj_id(thr), ref);
	return ref;
}

VALUE thread_delete_reference(VALUE thr)
{
	return rb_hash_delete(threads, rb_obj_id(thr));
}

void thread_pause()
{
	VALUE refs, r;
	thread_reference_t *ptr;
	long len, i;

	refs = rb_funcall(threads, rb_intern("values"), 0);
	len = rb_array_len(refs);
	for (i = 0; i < len; i++)
	{
		r = rb_ary_entry(refs, i);
		ptr = thread_reference_pointer(r);
		ptr->control = rb_intern("pause");
	}
}

VALUE thread_reference_push_frame(VALUE ref, VALUE tracepoint)
{
	VALUE frm_ary, frame;

	frm_ary = rb_funcall(ref, rb_intern("frames"), 0);
	frame = frame_new_from_tracepoint(tracepoint);
	rb_ary_unshift(frm_ary, frame);
	return frame;
}

VALUE thread_reference_update_frame(VALUE ref, VALUE tracepoint)
{
	VALUE frm_ary, frame;
	frm_ary = rb_funcall(ref, rb_intern("frames"), 0);
	frame = rb_ary_aref(0, frm_ary, Qnil);
	if (frame == Qnil)
	{
		return thread_reference_push_frame(ref, tracepoint);
		frame = frame_new_from_tracepoint(tracepoint);
		rb_ary_unshift(frm_ary, frame);
	}
	else
	{
		frame_update_from_tracepoint(frame, tracepoint);
	}
	return frame;
}

VALUE thread_reference_pop_frame(VALUE ref)
{
	VALUE frm_ary;
	frm_ary = rb_funcall(ref, rb_intern("frames"), 0);
	return rb_ary_shift(frm_ary);
}

void thread_reset()
{
	rb_funcall(threads, rb_intern("clear"), 0);
}

void initialize_threads(m_Readapt)
{
	c_Thread = rb_define_class_under(m_Readapt, "Thread", rb_cData);
	threads = rb_hash_new();
	rb_global_variable(&threads);
}
