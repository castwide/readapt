#include <math.h>
#include <stdlib.h>
#include <string.h>

#include "hash_table.h"
#include "prime.h"

// HT_DELETED_ITEM is used to mark a bucket containing a deleted item
static ht_item HT_DELETED_ITEM = {NULL, NULL};

// HT_PRIMEs are parameters in the hashing algorithm
static const int HT_PRIME_1 = 151;
static const int HT_PRIME_2 = 163;

static ht_long_array *copy_array(long *v, long size)
{
    long i;
    long *items = malloc(sizeof(long) * size);
    ht_long_array *result;

    for (i = 0; i < size; i++)
    {
        items[i] = v[i];
    }
    result = malloc(sizeof(ht_long_array));
    result->items = items;
    result->size = size;
    return result;
}

/*
 * Initialises a new item containing k: v
 */
static ht_item *ht_new_item(const char *k, const long *v, long size)
{
    ht_item *i = malloc(sizeof(ht_item));
    i->key = strdup(k);
    i->value = copy_array(v, size);
    return i;
}

/*
 * Deletes the ht_item i
 */
static void ht_del_item(ht_item *i)
{
    free(i->key);
    free(i->value->items); // TODO Does this free the whole array or just the first item?
    free(i);
}

/*
 * Initialises a new empty hash table using a particular size index
 */
static ht_hash_table *ht_new_sized(const int size_index)
{
    ht_hash_table *ht = malloc(sizeof(ht_hash_table));
    ht->size_index = size_index;

    const int base_size = 50 << ht->size_index;
    ht->size = next_prime(base_size);

    ht->count = 0;
    ht->items = calloc((size_t)ht->size, sizeof(ht_item *));
    return ht;
}

/*
 * Initialises a new empty hash table
 */
ht_hash_table *ht_new()
{
    return ht_new_sized(0);
}

/*
 * Deletes the hash table
 */
void ht_del_hash_table(ht_hash_table *ht)
{
    int i;

    // Iterate through items and delete any that are found
    for (i = 0; i < ht->size; i++)
    {
        ht_item *item = ht->items[i];
        if (item != NULL && item != &HT_DELETED_ITEM)
        {
            ht_del_item(item);
        }
    }
    free(ht->items);
    free(ht);
}

/*
 * Resize ht
 */
static void ht_resize(ht_hash_table *ht, const int direction)
{
    int i;

    const int new_size_index = ht->size_index + direction;
    if (new_size_index < 0)
    {
        // Don't resize down the smallest hash table
        return;
    }
    // Create a temporary new hash table to insert items into
    ht_hash_table *new_ht = ht_new_sized(new_size_index);
    // Iterate through existing hash table, add all items to new
    for (i = 0; i < ht->size; i++)
    {
        ht_item *item = ht->items[i];
        if (item != NULL && item != &HT_DELETED_ITEM)
        {
            ht_insert(new_ht, item->key, item->value->items, item->value->size);
        }
    }

    // Pass new_ht and ht's properties. Delete new_ht
    ht->size_index = new_ht->size_index;
    ht->count = new_ht->count;

    // To delete new_ht, we give it ht's size and items
    const int tmp_size = ht->size;
    ht->size = new_ht->size;
    new_ht->size = tmp_size;

    ht_item **tmp_items = ht->items;
    ht->items = new_ht->items;
    new_ht->items = tmp_items;

    ht_del_hash_table(new_ht);
}

/*
 * Returns the hash of 's', an int between 0 and 'm'.
 */
static int ht_generic_hash(const char *s, const int a, const int m)
{
    long hash = 0;
    int i;
    const int len_s = strlen(s);

    for (i = 0; i < len_s; i++)
    {
        /* Map char to a large integer */
        hash += (long)pow(a, len_s - (i + 1)) * s[i];
        hash = hash % m;
    }
    // hash has just been moduloed, so should be below the max int size, as
    // long as the number of buckets are low enough.
    return (int)hash;
}

static int ht_hash(const char *s, const int num_buckets, const int attempt)
{
    const int hash_a = ht_generic_hash(s, HT_PRIME_1, num_buckets);
    const int hash_b = ht_generic_hash(s, HT_PRIME_2, num_buckets);
    return (hash_a + (attempt * (hash_b + 1))) % num_buckets;
}

/*
 * Inserts the 'key': 'value' pair into the hash table
 */
void ht_insert(ht_hash_table *ht, const char *key, const long *value, const long size)
{
    ht_item *item;
    ht_item *cur_item;
    int load, index, i;

    // Resize if load > 0.7
    load = ht->count * 100 / ht->size;
    if (load > 70)
    {
        ht_resize(ht, 1);
    }
    item = ht_new_item(key, value, size);

    // Cycle though filled buckets until we hit an empty or deleted one
    index = ht_hash(item->key, ht->size, 0);
    cur_item = ht->items[index];
    i = 1;
    while (cur_item != NULL && cur_item != &HT_DELETED_ITEM)
    {
        if (strcmp(cur_item->key, key) == 0)
        {
            ht_del_item(cur_item);
            ht->items[index] = item;
            return;
        }
        index = ht_hash(item->key, ht->size, i);
        cur_item = ht->items[index];
        i++;
    }

    // index points to a free bucket
    ht->items[index] = item;
    ht->count++;
}

/*
 * Returns the value associated with 'key', or NULL if the key doesn't exist
 */
ht_long_array *ht_search(ht_hash_table *ht, const char *key)
{
    int index = ht_hash(key, ht->size, 0);
    ht_item *item = ht->items[index];
    int i = 1;
    while (item != NULL && item != &HT_DELETED_ITEM)
    {
        if (strcmp(item->key, key) == 0)
        {
            return item->value;
        }
        index = ht_hash(key, ht->size, i);
        item = ht->items[index];
        i++;
    }
    return NULL;
}

/*
 * Deletes key's item from the hash table. Does nothing if 'key' doesn't exist
 */
void ht_delete(ht_hash_table *ht, const char *key)
{
    int load, index, i;
    ht_item *item;

    // Resize if load < 0.1
    load = ht->count * 100 / ht->size;
    if (load < 10)
    {
        ht_resize(ht, -1);
    }

    index = ht_hash(key, ht->size, 0);
    item = ht->items[index];
    i = 1;
    while (item != NULL && item != &HT_DELETED_ITEM)
    {
        if (strcmp(item->key, key) == 0)
        {
            ht_del_item(item);
            ht->items[index] = &HT_DELETED_ITEM;
        }
        index = ht_hash(key, ht->size, i);
        item = ht->items[index];
        i++;
    }
    ht->count--;
}
