#include "ruby.h"
#include "ruby/debug.h"
#include "frame.h"

static VALUE c_Frame;

static void
frame_free(void* data)
{
    frame_t *frm = data;
    free(frm->file);
    free(frm);
}

static size_t
frame_size(const void* data)
{
    return sizeof(frame_t);
}

static const rb_data_type_t frame_type = {
	.wrap_struct_name = "frame_data",
	.function = {
		.dmark = NULL,
		.dfree = frame_free,
		.dsize = frame_size,
	},
	.data = NULL,
	.flags = RUBY_TYPED_FREE_IMMEDIATELY,
};

VALUE frame_allocate_s(VALUE self)
{
    VALUE obj;
    frame_t *data = malloc(sizeof(frame_t));
    obj = TypedData_Wrap_Struct(self, &frame_type, data);
    data->file = NULL;
    data->line = 0;
    data->method_id = rb_intern("");
    data->binding_id = 0;
    return obj;
}

VALUE frame_allocate()
{
    return frame_allocate_s(c_Frame);
}

VALUE frame_new_from_tracepoint(VALUE tracepoint)
{
    VALUE frm;

    frm = frame_allocate();
    return frame_update_from_tracepoint(frm, tracepoint);
}

static char* copy_string(VALUE string)
{
    char *dst;
    char *src;

    if (string == Qnil)
    {
        return NULL;
    }
    src = StringValueCStr(string);
    dst = malloc(sizeof(char) * (strlen(src) + 1));
    strcpy(dst, src);
    return dst;
}

VALUE frame_update_from_tracepoint(VALUE frame, VALUE tracepoint)
{
	VALUE tmp, bnd;
	rb_trace_arg_t *tracearg;
    frame_t *data;
    char *file;
    int line;
	ID method_id;
	long binding_id;

    tracearg = rb_tracearg_from_tracepoint(tracepoint);
    tmp = rb_tracearg_path(tracearg);
    file = copy_string(tmp);
    line = NUM2INT(rb_tracearg_lineno(tracearg));
	method_id = rb_intern("placeholder"); // TODO Get the real one
	bnd = rb_tracearg_binding(tracearg);
	binding_id = NUM2LONG(rb_obj_id(bnd));

    TypedData_Get_Struct(frame, frame_t, &frame_type, data);
    free(data->file);
    data->file = file;
    data->line = line;
    data->method_id = method_id;
    data->binding_id = binding_id;

    return frame;
}

VALUE frame_initialize_m(VALUE self, VALUE file, VALUE line, VALUE method_id, VALUE binding_id)
{
    frame_t *data;
    TypedData_Get_Struct(self, frame_t, &frame_type, data);
    data->file = copy_string(file);
    data->line = NUM2INT(line);
    data->method_id = rb_intern("placeholder"); // TODO Real value
    data->binding_id = NUM2LONG(binding_id);
    return self;
}

VALUE frame_file(VALUE self)
{
    frame_t *data;
    VALUE str = Qnil;

    TypedData_Get_Struct(self, frame_t, &frame_type, data);
    if (data->file)
    {
        str = rb_str_new_cstr(data->file);
        rb_obj_freeze(str);
    }
    return str;
}

VALUE frame_line(VALUE self)
{
    frame_t *data;
    TypedData_Get_Struct(self, frame_t, &frame_type, data);
    return INT2NUM(data->line);
}

VALUE frame_method_id(VALUE self)
{
    frame_t *data;
    TypedData_Get_Struct(self, frame_t, &frame_type, data);
    return ID2SYM(data->method_id);
}

VALUE frame_binding_id(VALUE self)
{
    frame_t *data;
    TypedData_Get_Struct(self, frame_t, &frame_type, data);
    return LONG2NUM(data->binding_id);
}

void initialize_frame(VALUE m_Readapt)
{
    c_Frame = rb_define_class_under(m_Readapt, "Frame", rb_cData);
    rb_define_alloc_func(c_Frame, frame_allocate_s);
    rb_define_method(c_Frame, "initialize", frame_initialize_m, 4);
    rb_define_method(c_Frame, "file", frame_file, 0);
    rb_define_method(c_Frame, "line", frame_line, 0);
    rb_define_method(c_Frame, "method_id", frame_method_id, 0);
    rb_define_method(c_Frame, "binding_id", frame_binding_id, 0);
}
