#include "ruby.h"
#include "ruby/debug.h"
#include "threads.h"
#include "frame.h"
#include "inspector.h"

static VALUE c_Thread;
static VALUE threads;
static VALUE ids;
static int next_id;

static void thread_reference_free(void* data)
{
	thread_reference_t* thr;

	thr = data;
	stack_free(thr->frames);
	free(thr);
}

static size_t thread_reference_size(const void* data)
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

static VALUE thread_reference_new(VALUE thr)
{
	thread_reference_t *data = malloc(sizeof(thread_reference_t));
	VALUE obj = TypedData_Make_Struct(c_Thread, thread_reference_t, &thread_reference_type, data);
	data->id = next_id;
	data->cursor = 0;
	data->depth = 0;
	data->control = rb_intern("continue");
	data->frames = stack_alloc(sizeof(frame_t), frame_free);
    data->thread_object_id = NUM2LONG(rb_obj_id(thr));
    next_id++;
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
	return rb_hash_aref(ids, id);
}

VALUE thread_add_reference(VALUE thr)
{
	VALUE ref;
	thread_reference_t *ptr;

	ref = thread_reference_new(thr);
	ptr = thread_reference_pointer(ref);
	rb_hash_aset(threads, rb_obj_id(thr), ref);
	rb_hash_aset(ids, INT2NUM(ptr->id), ref);
	return ref;
}

VALUE thread_delete_reference(VALUE thr)
{
	// TODO: Do we need to delete from ids here?
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

void thread_clear()
{
	rb_funcall(threads, rb_intern("clear"), 0);
	rb_funcall(ids, rb_intern("clear"), 0);
}

static VALUE thread_allocate_s(VALUE self)
{
	thread_reference_t *data = malloc(sizeof(thread_reference_t));
	data->control = rb_intern("continue");
	data->depth = 0;
	data->cursor = 0;
	data->frames = stack_alloc(sizeof(frame_t), frame_free);
	data->id = 0;
	return TypedData_Wrap_Struct(self, &thread_reference_type, data);
}

static VALUE thread_all_s(VALUE self)
{
	return rb_funcall(threads, rb_intern("values"), 0);
}

static VALUE thread_find_s(VALUE self, VALUE id)
{
	return thread_reference_id(id);
}

static VALUE thread_include_s(VALUE self, VALUE id)
{
	return rb_funcall(ids, rb_intern("include?"), 1, id);
}

static VALUE thread_id_m(VALUE self)
{
	thread_reference_t *data = thread_reference_pointer(self);
	return LONG2NUM(data->id);
}

static VALUE frames_m(VALUE self)
{
	thread_reference_t *data;
	VALUE ary;
	VALUE frm;
	int i;
	frame_t *fd;

	ary = rb_ary_new();
	data = thread_reference_pointer(self);
	for (i = data->frames->size - 1; i >= 0; i--)
	{
		fd = data->frames->elements[i];
		// TODO This condition should probably not be necessary.
		if (fd->binding != Qnil)
		{
			frm = frame_new_from_data(fd);
			rb_ary_push(ary, frm);
		}
	}

	return ary;
}

static VALUE thread_object_id_m(VALUE self)
{
	thread_reference_t *data;

    data = thread_reference_pointer(self);
    return LONG2NUM(data->thread_object_id);
    // return rb_hash_aref(ids, INT2NUM(data->id))->object_id;
}

void thread_reference_build_frames(thread_reference_t *ptr)
{
	inspector_inspect(ptr);
}

void thread_reference_clear_frames(thread_reference_t *ptr)
{
	stack_free(ptr->frames);
	ptr->frames = stack_alloc(sizeof(frame_t), frame_free);
}

void initialize_threads(VALUE m_Readapt)
{
	next_id = 1;

	c_Thread = rb_define_class_under(m_Readapt, "Thread", rb_cObject);
	rb_define_alloc_func(c_Thread, thread_allocate_s);
	rb_define_method(c_Thread, "id", thread_id_m, 0);
	rb_define_method(c_Thread, "frames", frames_m, 0);
    rb_define_method(c_Thread, "thread_object_id", thread_object_id_m, 0);
    rb_define_singleton_method(c_Thread, "all", thread_all_s, 0);
	rb_define_singleton_method(c_Thread, "find", thread_find_s, 1);
	rb_define_singleton_method(c_Thread, "include?", thread_include_s, 1);

	threads = rb_hash_new();
	rb_global_variable(&threads);
	ids = rb_hash_new();
	rb_global_variable(&ids);
}
