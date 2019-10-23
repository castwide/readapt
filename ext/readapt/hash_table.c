#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "hash_table.h"

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
    result->items = (size ? items : NULL);
    result->size = size;
    return result;
}

/*
 * Initialize a new item
 */
static ht_item *ht_new_item(char *key, const long *value, const long size)
{
    ht_item *i = malloc(sizeof(ht_item));
    i->key = malloc(sizeof(char) * (strlen(key) + 1));
    strcpy(i->key, key);
    i->value = copy_array(value, size);
    return i;
}

/*
 * Delete the ht_item
 */
static void ht_del_item(ht_item *i)
{
    free(i->key);
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

static ht_long_array *ht_search_part(ht_hash_table *ht, char *key, long cursor, long next)
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
            return ht_search_part(ht, key, next + 1, next + ((ht->size - next) / 2));
        }
        else
        {
            return ht_search_part(ht, key, cursor + 1, next / 2);
        }
    }
    return ht_search_part(ht, key, cursor + 1, next / 2);
}

static ht_long_array *ht_search_key(ht_hash_table *ht, char *key)
{
    return ht_search_part(ht, key, 0, ht->size / 2);
}

static void ht_delete_key(ht_hash_table *ht, char *key)
{
    ht_long_array *found;
    ht_item **tmp;
    long i;
    long cursor = 0;

    found = ht_search_key(ht, key);
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

static void ht_insert_key(ht_hash_table *ht, char *key, const long *value, const long size)
{
    ht_item *item;
    ht_item **tmp;
    long i;
    long cursor = 0;
    int inserted = 0;
    int cmp;

    ht_delete_key(ht, key);

    if (size == 0)
    {
        return;
    }

    item = ht_new_item(key, value, size);
    tmp = malloc(sizeof(ht_item) * (ht->size + 1));

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
 * Add an item to the hash table
 */
void ht_insert(ht_hash_table *ht, char *key, const long *value, const long size)
{
    ht_insert_key(ht, key, value, size);
}

/*
 * Get the key's value or NULL if it doesn't exist
 */
ht_long_array *ht_search(ht_hash_table *ht, char *key)
{
    return ht_search_key(ht, key);
}

/*
 * Delete the key's item if it exists
 */
void ht_delete(ht_hash_table *ht, char *key)
{
    ht_delete_key(ht, key);
}
