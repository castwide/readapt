#include "ruby.h"
#include "hash_table.h"

static VALUE m_Breakpoints;
ht_hash_table *ht;

void breakpoints_set(char *file, long *lines)
{

}

static VALUE breakpoints_set_s(VALUE self, VALUE file, VALUE lines)
{
    long length = NUM2LONG(rb_funcall(lines, rb_intern("length"), 0));
    long *ll;
    long i;

    ll = malloc(sizeof(long) * length);
    for (i = 0; i < length; i++)
    {
        ll[i] = NUM2LONG(rb_ary_entry(lines, i));
    }
    ht_insert(ht, StringValueCStr(file), ll, length);
    free(ll);
    return Qnil;
}

void breakpoints_delete(char *file)
{

}

static VALUE breakpoints_delete_s(VALUE self, VALUE file)
{
    return Qnil;
}

int breakpoints_match(char *file, long line)
{
    ht_long_array *lines;
    long i;

    lines = ht_search(ht, file);
    if (lines != NULL)
    {
        for (i = 0; i < lines->size; i++)
        {
            if (lines->items[i] == line)
            {
                return 1;
            }
        }
    }
    return 0;
}

static VALUE breakpoints_match_s(VALUE self, VALUE file, VALUE line)
{
    return breakpoints_match(StringValueCStr(file), NUM2LONG(line)) == 0 ? Qfalse : Qtrue;
}

static VALUE breakpoints_clear_s(VALUE self)
{
    ht_del_hash_table(ht);
    ht = ht_new();
    return Qnil;
}

long breakpoints_files()
{
    return ht->size;
}

void initialize_breakpoints(VALUE m_Readapt)
{
    m_Breakpoints = rb_define_module_under(m_Readapt, "Breakpoints");
    rb_define_singleton_method(m_Breakpoints, "set", breakpoints_set_s, 2);
    rb_define_singleton_method(m_Breakpoints, "delete", breakpoints_delete_s, 1);
    rb_define_singleton_method(m_Breakpoints, "match", breakpoints_match_s, 2);
    rb_define_singleton_method(m_Breakpoints, "clear", breakpoints_clear_s, 0);

    ht = ht_new(); // TODO Need to free?
}
