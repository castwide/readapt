#include "ruby.h"
#include "ruby/debug.h"
#include <ctype.h>

static int isWindows;

static int
checkIfWindows()
{
    VALUE regexp, result;
    
    regexp = rb_reg_new("/cygwin|mswin|mingw|bccwin|wince|emx/", 37, 0);
    result = rb_reg_match(regexp, rb_str_new_cstr(RUBY_PLATFORM));
    return result == Qnil ? 0 : 1;
}

void normalize_path(char *str)
{
    long i, len;

    if (isWindows)
    {
        str[0] = toupper(str[0]);
        len = strlen(str);
        for (i = 2; i < len; i++)
        {
            if (str[i] == '\\')
            {
                str[i] = '/';
            }
        }
    }
}

char *normalize_path_new_cstr(char *str)
{
    char *buffer;

    buffer = malloc((strlen(str) + 1) * sizeof(char));
    strcpy(buffer, str);
    normalize_path(buffer);
    return buffer;
}

static VALUE
normalize_path_s(VALUE self, VALUE str)
{
    char *path = normalize_path_new_cstr(StringValueCStr(str));
    VALUE result = rb_str_new_cstr(path);
    free(path);
    return result;
}

void initialize_normalize(VALUE m_Readapt)
{
    isWindows = checkIfWindows();
    
    rb_define_singleton_method(m_Readapt, "normalize_path", normalize_path_s, 1);
}
