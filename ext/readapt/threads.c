#include "ruby.h"
#include "ruby/debug.h"
#include "threads.h"
#include "frame.h"

#define FRAME_CAPACITY 100;

static VALUE c_Thread;
static VALUE threads;

void thread_reference_free(void* data)
{
	thread_reference_t* thr;
	int i;

	thr = data;
	for (i = 0; i < thr->depth; i++)
	{
		frame_free(thr->frames[i]);
	}
	free(thr->frames);
	free(thr);
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
	data->capacity = FRAME_CAPACITY;
	data->cursor = 0;
	data->control = rb_intern("continue");
	data->frames = malloc(sizeof(frame_t) * data->capacity);
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

void thread_increment_depth(VALUE ref)
{
	thread_reference_t *data;
	data = thread_reference_pointer(ref);
	data->depth++;
}

void thread_decrement_depth(VALUE ref)
{
	thread_reference_t *data;
	data = thread_reference_pointer(ref);
	data->depth--;
}

void thread_reference_push_frame(VALUE ref, VALUE tracepoint)
{
	thread_reference_t *data;

	data = thread_reference_pointer(ref);
	if (data->depth == data->capacity)
	{
		data->capacity += FRAME_CAPACITY;
		realloc(data->frames, sizeof(frame_t) * data->capacity);
	}
	data->frames[data->depth] = frame_data_from_tracepoint(tracepoint);
	data->depth++;
}

frame_t *thread_reference_update_frame(VALUE ref, VALUE tracepoint)
{
	thread_reference_t *data;

	data = thread_reference_pointer(ref);
	if (data->depth == 0)
	{
		thread_reference_push_frame(ref, tracepoint);
	}
	else
	{
		frame_update_from_tracepoint(tracepoint, data->frames[data->depth - 1]);
	}

	return data->frames[data->depth - 1];
}

void thread_reference_pop_frame(VALUE ref)
{
	thread_reference_t *data;

	data = thread_reference_pointer(ref);
	if (data->depth > 0)
	{
		frame_free(data->frames[data->depth - 1]);
		data->frames[data->depth - 1] = NULL;
		data->depth--;
	}
}

void thread_clear()
{
	rb_funcall(threads, rb_intern("clear"), 0);
}

VALUE thread_allocate_s(VALUE self)
{
	thread_reference_t *data = malloc(sizeof(thread_reference_t));
	data->control = rb_intern("continue");
	data->depth = 0;
	data->cursor = 0;
	data->capacity = FRAME_CAPACITY;
	data->frames = malloc(sizeof(frame_t) * data->capacity);
	data->id = 0;
	return TypedData_Wrap_Struct(self, &thread_reference_type, data);
}

VALUE thread_all_s(VALUE self)
{
	return rb_funcall(threads, rb_intern("values"), 0);
}

VALUE thread_find_s(VALUE self, VALUE id)
{
	return thread_reference_id(id);
}

VALUE thread_include_s(VALUE self, VALUE id)
{
	return rb_funcall(threads, rb_intern("include?"), 1, id);
}

VALUE thread_id_m(VALUE self)
{
	thread_reference_t *data = thread_reference_pointer(self);
	return LONG2NUM(data->id);
}

VALUE frames_m(VALUE self)
{
	thread_reference_t *data;
	VALUE ary;
	VALUE frm;
	int i;

	ary = rb_ary_new();
	data = thread_reference_pointer(self);
	for (i = data->depth - 1; i >= 0; i--)
	{
		frm = frame_new_from_data(data->frames[i]);
		rb_ary_push(ary, frm);
	}

	return ary;
}

void initialize_threads(VALUE m_Readapt)
{
	c_Thread = rb_define_class_under(m_Readapt, "Thread", rb_cData);
	rb_define_alloc_func(c_Thread, thread_allocate_s);
	rb_define_method(c_Thread, "id", thread_id_m, 0);
	rb_define_method(c_Thread, "frames", frames_m, 0);
	rb_define_singleton_method(c_Thread, "all", thread_all_s, 0);
	rb_define_singleton_method(c_Thread, "find", thread_find_s, 1);
	rb_define_singleton_method(c_Thread, "include?", thread_include_s, 1);

	threads = rb_hash_new();
	rb_global_variable(&threads);
}
