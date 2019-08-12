#include "ruby.h"
#include "ruby/debug.h"

static int isWindows;

static int
checkIfWindows()
{
    VALUE regexp, result;
    
    regexp = rb_reg_new("/cygwin|mswin|mingw|bccwin|wince|emx/", 37, 0);
    result = rb_reg_match(regexp, rb_str_new_cstr(RUBY_PLATFORM));
    return result == Qnil ? 0 : 1;
}

VALUE
normalize_path(VALUE str)
{
    VALUE result;
    char *buffer;
    long i, len;

    if (isWindows)
    {
        buffer = malloc((rb_str_strlen(str) + 1) * sizeof(char));
        strcpy(buffer, StringValueCStr(str));
        buffer[0] = toupper(buffer[0]);
        len = strlen(buffer);
        for (i = 2; i < len; i++)
        {
            if (buffer[i] == '\\')
            {
                buffer[i] = '/';
            }
        }
        result = rb_str_new_cstr(buffer);
        free(buffer);
        return result;
    }
    return str;
}

static VALUE
normalize_path_s(VALUE self, VALUE str)
{
    return normalize_path(str);
}

void initialize_normalize(VALUE m_Readapt)
{
    isWindows = checkIfWindows();
    
    rb_define_singleton_method(m_Readapt, "normalize_path", normalize_path_s, 1);
}
