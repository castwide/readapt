#include "ruby.h"
#include "ruby/debug.h"
#include "frame.h"

static size_t
inspector_size(const void *data)
{
    return sizeof(void *);
}

static const rb_data_type_t inspector_type = {
    "inspector",
    {0, 0, inspector_size,},
};

static const rb_debug_inspector_t *
rb_debug_inspector_from_location(VALUE self)
{
    const rb_debug_inspector_t *dc;
    TypedData_Get_Struct(self, const rb_debug_inspector_t, &inspector_type, dc);
    if (dc == 0) {
    	rb_raise(rb_eArgError, "invalid debug context");
    }
    return dc;
}

static VALUE process_inspection(const rb_debug_inspector_t *inspector, void *ptr)
{
    VALUE m_Readapt;
    VALUE c_Frame;

    VALUE locations;
    VALUE size;
    long i_size;
    long i;
    VALUE loc;
    VALUE path;
    VALUE line;
    VALUE bnd;
    VALUE id;
    VALUE frames;
    VALUE frm;

    m_Readapt = rb_const_get(rb_cObject, rb_intern("Readapt"));
    c_Frame = rb_const_get(m_Readapt, rb_intern("Frame"));

    locations = rb_debug_inspector_backtrace_locations(inspector);
    size = rb_funcall(locations, rb_intern("size"), 0);
    i_size = NUM2LONG(size);
    frames = rb_ary_new();
    for (i = 0; i < i_size; i++)
    {
        loc = rb_ary_entry(locations, i);
        path = rb_funcall(loc, rb_intern("absolute_path"), 0);

        line = rb_funcall(loc, rb_intern("lineno"), 0);

        bnd = rb_debug_inspector_frame_binding_get(inspector, i);
        id = rb_obj_id(bnd);

        // frm = rb_funcall(c_Frame, rb_intern("new"), 3, path, line, bnd);

        // rb_ary_push(frames, frm);
    }

    return frames;
}

static VALUE
open_body(VALUE self)
{
    return rb_debug_inspector_open(process_inspection, (void *)self);
}

static VALUE
ensure_body(VALUE self)
{
    DATA_PTR(self) = 0;
    return self;
}

/**
 * Get an array of frames from the Ruby debug inspector.
 */
void inspector_inspect(VALUE thread)
{
    rb_debug_inspector_open(process_inspection, (void *)thread);
}
