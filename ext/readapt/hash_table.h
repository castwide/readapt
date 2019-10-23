#ifndef HASH_TABLE_H_
#define HASH_TABLE_H_

typedef struct ht_long_array
{
    long *items;
    long size;
} ht_long_array;

// ht_item is an item in the hash table
typedef struct ht_item
{
    char *key;
    ht_long_array *value;
} ht_item;

typedef struct ht_hash_table
{
    long size;
    ht_item **items;
} ht_hash_table;

ht_hash_table *ht_new();
void ht_del_hash_table(ht_hash_table *ht);

void ht_insert(ht_hash_table *ht, char *key, const long *value, const long size);
ht_long_array *ht_search(ht_hash_table *ht, char *key);
void ht_delete(ht_hash_table *h, char *key);

#endif // HASH_TABLE_H_
