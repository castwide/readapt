#ifndef LOOKUP_TABLE_H_
#define LOOKUP_TABLE_H_

typedef struct lt_long_array
{
    long *items;
    long size;
} lt_long_array;

// lt_item is an item in the lookup table
typedef struct lt_item
{
    char *key;
    lt_long_array *value;
} lt_item;

typedef struct lt_lookup_table
{
    long size;
    lt_item **items;
} lt_lookup_table;

lt_lookup_table *lt_new();
void lt_del_lookup_table(lt_lookup_table *ht);

void lt_insert(lt_lookup_table *ht, char *key, const long *value, const long size);
lt_long_array *lt_search(lt_lookup_table *ht, char *key);
void lt_delete(lt_lookup_table *h, char *key);

#endif // LOOKUP_TABLE_H_
