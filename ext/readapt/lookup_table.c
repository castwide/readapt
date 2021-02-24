#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "lookup_table.h"

static lt_long_array *copy_array(const long *value, const long size)
{
    long i;
    long *items = malloc(sizeof(long) * size);
    lt_long_array *result;

    for (i = 0; i < size; i++)
    {
        items[i] = value[i];
    }
    result = malloc(sizeof(lt_long_array));
    result->items = (size ? items : NULL);
    result->size = size;
    return result;
}

/*
 * Initialize a new item
 */
static lt_item *lt_new_item(char *key, const long *value, const long size)
{
    lt_item *i = malloc(sizeof(lt_item));
    i->key = malloc(sizeof(char) * (strlen(key) + 1));
    strcpy(i->key, key);
    i->value = copy_array(value, size);
    return i;
}

/*
 * Delete the lt_item
 */
static void lt_del_item(lt_item *i)
{
    free(i->key);
    free(i->value->items);
    free(i);
}

/*
 * Initialize a new empty lookup table
 */
lt_lookup_table *lt_new()
{
    lt_lookup_table *ht = malloc(sizeof(lt_lookup_table));
    ht->items = NULL;
    ht->size = 0;
    return ht;
}

/*
 * Delete the lookup table
 */
void lt_del_lookup_table(lt_lookup_table *ht)
{
    int i;
    lt_item *item;

    // Iterate through items and delete any that are found
    for (i = 0; i < ht->size; i++)
    {
        item = ht->items[i];
        lt_del_item(item);
    }
    free(ht->items);
    free(ht);
}

static lt_long_array *lt_search_part(lt_lookup_table *ht, char *key, long cursor, long next)
{
    int cmp;

    if (cursor >= ht->size)
    {
        return NULL;
    }

    cmp = strcmp(ht->items[cursor]->key, key);
    if (cmp == 0)
    {
        return ht->items[cursor]->value;
    }
    if (next > cursor && next < ht->size)
    {
        cmp = strcmp(ht->items[next]->key, key);
        if (cmp == 0)
        {
            return ht->items[next]->value;
        }
        else if (cmp < 0)
        {
            return lt_search_part(ht, key, next + 1, next + ((ht->size - next) / 2));
        }
        else
        {
            return lt_search_part(ht, key, cursor + 1, next / 2);
        }
    }
    return lt_search_part(ht, key, cursor + 1, next / 2);
}

static lt_long_array *lt_search_key(lt_lookup_table *ht, char *key)
{
    return lt_search_part(ht, key, 0, ht->size / 2);
}

static void lt_delete_key(lt_lookup_table *ht, char *key)
{
    lt_long_array *found;
    lt_item **tmp;
    long i;
    long cursor = 0;

    found = lt_search_key(ht, key);
    if (found)
    {
        tmp = malloc(sizeof(lt_item) * (ht->size - 1));
        for (i = 0; i < ht->size; i++)
        {
            if (ht->items[i]->key == key)
            {
                lt_del_item(ht->items[i]);
            }
            else
            {
                tmp[cursor] = ht->items[cursor];
                cursor++;
            }
        }
        free(ht->items);
        ht->items = tmp;
        ht->size--;
    }
}

static void lt_insert_key(lt_lookup_table *ht, char *key, const long *value, const long size)
{
    lt_item *item;
    lt_item **tmp;
    long i;
    long cursor = 0;
    int inserted = 0;
    int cmp;

    lt_delete_key(ht, key);

    if (size == 0)
    {
        return;
    }

    item = lt_new_item(key, value, size);
    tmp = malloc(sizeof(lt_item) * (ht->size + 1));

    for (i = 0; i < ht->size; i++)
    {
        if (!inserted)
        {
            cmp = strcmp(item->key, ht->items[i]->key);
            if (cmp > 0)
            {
                tmp[cursor] = item;
                cursor++;
                inserted = 1;
            }
            tmp[cursor] = ht->items[i];
            cursor++;
        }
        else
        {
            tmp[cursor] = ht->items[i];
            cursor++;
        }
    }
    if (!inserted)
    {
        tmp[ht->size] = item;
    }
    free(ht->items);
    ht->items = tmp;
    ht->size++;
}

/*
 * Add an item to the lookup table
 */
void lt_insert(lt_lookup_table *ht, char *key, const long *value, const long size)
{
    lt_insert_key(ht, key, value, size);
}

/*
 * Get the key's value or NULL if it doesn't exist
 */
lt_long_array *lt_search(lt_lookup_table *ht, char *key)
{
    return lt_search_key(ht, key);
}

/*
 * Delete the key's item if it exists
 */
void lt_delete(lt_lookup_table *ht, char *key)
{
    lt_delete_key(ht, key);
}
