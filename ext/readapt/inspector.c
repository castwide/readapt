#include "ruby.h"
#include "ruby/debug.h"
#include "frame.h"
#include "threads.h"
#include "normalize.h"

static VALUE process_inspection(const rb_debug_inspector_t *inspector, void *ptr)
{
    VALUE locations;
    long i_size;
    long i;
    VALUE loc;
    VALUE path;
    int line;
    VALUE bnd;
    thread_reference_t *data;
    frame_t *frm;
    VALUE iseq;

    data = ptr;

    locations = rb_debug_inspector_backtrace_locations(inspector);
    i_size = locations == Qnil ? 0 : RARRAY_LENINT(locations);
    for (i = i_size - 1; i >= 0; i--)
    {
        iseq = rb_debug_inspector_frame_iseq_get(inspector, i);
        if (iseq != Qnil)
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
    }

    return Qnil;
}

/**
 * Get an array of frames from the Ruby debug inspector.
 */
void inspector_inspect(thread_reference_t *data)
{
    rb_debug_inspector_open(process_inspection, (void *)data);
}
