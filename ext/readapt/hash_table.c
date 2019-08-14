#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "hash_table.h"
#include "ruby.h"

static ht_long_array *copy_array(const long *value, const long size)
{
    long i;
    long *items = malloc(sizeof(long) * size);
    ht_long_array *result;

    for (i = 0; i < size; i++)
    {
        items[i] = value[i];
    }
    result = malloc(sizeof(ht_long_array));
    result->items = items;
    result->size = size;
    return result;
}

/*
 * Initialize a new item
 */
static ht_item *ht_new_item(ID key, const long *value, const long size)
{
    ht_item *i = malloc(sizeof(ht_item));
    i->key = key;
    i->value = copy_array(value, size);
    return i;
}

/*
 * Delete the ht_item
 */
static void ht_del_item(ht_item *i)
{
    free(i->value->items);
    free(i);
}

/*
 * Initialize a new empty hash table
 */
ht_hash_table *ht_new()
{
    ht_hash_table *ht = malloc(sizeof(ht_hash_table));
    ht->items = NULL;
    ht->size = 0;
    return ht;
}

/*
 * Delete the hash table
 */
void ht_del_hash_table(ht_hash_table *ht)
{
    int i;
    ht_item *item;

    // Iterate through items and delete any that are found
    for (i = 0; i < ht->size; i++)
    {
        item = ht->items[i];
        ht_del_item(item);
    }
    free(ht->items);
    free(ht);
}

/*
 * Add an item to the hash table
 */
void ht_insert(ht_hash_table *ht, ID key, const long *value, const long size)
{
    ht_item *item;
    ht_item **tmp;
    long i;
    long cursor = 0;
    int inserted = 0;

    ht_delete(ht, key);

    item = ht_new_item(key, value, size);
    tmp = malloc(sizeof(ht_item) * (ht->size + 1));

    for (i = 0; i <= ht->size; i++)
    {
        if (!inserted)
        {
            if (i == ht->size)
            {
                tmp[i] = item;
                inserted = 1;
            }
            else
            {
                if (item->key > ht->items[i]->key)
                {
                    tmp[i] = item;
                    tmp[i + 1] = ht->items[cursor];
                    inserted = 1;
                    cursor++;
                    i++;
                }
            }
        }
        else
        {
            tmp[i] = ht->items[cursor];
            cursor++;
        }
    }
    free(ht->items);
    ht->items = tmp;
    ht->size++;
}

static ht_long_array *ht_search_part(ht_hash_table *ht, ID key, long cursor, long next)
{
    if (cursor >= ht->size)
    {
        return NULL;
    }

    if (ht->items[cursor]->key == key)
    {
        return ht->items[cursor]->value;
    }
    if (next > cursor && next < ht->size)
    {
        if (ht->items[next]->key == key)
        {
            return ht->items[next]->value;
        }
        if (ht->items[next]->key > key)
        {
            return ht_search_part(ht, key, next + 1, next + ((ht->size - next) / 2));
        }
        else
        {
            return ht_search_part(ht, key, cursor + 1, next / 2);
        }
    }
    return ht_search_part(ht, key, cursor + 1, next / 2);
}

/*
 * Get the key's value or NULL if it doesn't exist
 */
ht_long_array *ht_search(ht_hash_table *ht, ID key)
{
    return ht_search_part(ht, key, 0, ht->size / 2);
}

/*
 * Delete the key's item if it exists
 */
void ht_delete(ht_hash_table *ht, ID key)
{
    ht_long_array *found;
    ht_item **tmp;
    long i;
    long cursor = 0;

    found = ht_search(ht, key);
    if (found)
    {
        tmp = malloc(sizeof(ht_item) * (ht->size - 1));
        for (i = 0; i < ht->size; i++)
        {
            if (ht->items[i]->key == key)
            {
                ht_del_item(ht->items[i]);
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
