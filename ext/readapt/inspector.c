#include "ruby.h"
#include "ruby/debug.h"
#include "frame.h"
#include "threads.h"
#include "normalize.h"

static VALUE process_inspection(const rb_debug_inspector_t *inspector, void *ptr)
{
    VALUE locations;
    VALUE size;
    long i_size;
    long i;
    VALUE loc;
    VALUE path;
    int line;
    VALUE bnd;
    thread_reference_t *data;
    frame_t *frm;

    data = ptr;

    locations = rb_debug_inspector_backtrace_locations(inspector);
    size = rb_funcall(locations, rb_intern("size"), 0);
    i_size = NUM2INT(size);
    for (i = i_size - 1; i >= 0; i--)
    {
        loc = rb_ary_entry(locations, i);
        path = rb_funcall(loc, rb_intern("absolute_path"), 0);
        line = NUM2INT(rb_funcall(loc, rb_intern("lineno"), 0));
        bnd = rb_debug_inspector_frame_binding_get(inspector, i);

        frm = malloc(sizeof(frame_t));
        frm->file = normalize_path_new_cstr(StringValueCStr(path));
        frm->line = line;
        frm->binding = bnd;
        stack_push(data->frames, frm);
    }

    return Qnil;
}

// static VALUE
// open_body(VALUE self)
// {
//     return rb_debug_inspector_open(process_inspection, (void *)self);
// }

// static VALUE
// ensure_body(VALUE self)
// {
//     DATA_PTR(self) = 0;
//     return self;
// }

/**
 * Get an array of frames from the Ruby debug inspector.
 */
void inspector_inspect(thread_reference_t *data)
{
    rb_debug_inspector_open(process_inspection, (void *)data);
}
