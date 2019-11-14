#ifndef STACK_H_
#define STACK_H_

#include "stddef.h"

typedef struct readapt_stack_struct {
    int size;
    size_t elem_size;
    void (*free_func)(void *);
    int capacity;
    void **elements;
} readapt_stack_t;

readapt_stack_t *stack_alloc(size_t elem_size, void(*free_func)(void*));
void stack_push(readapt_stack_t *stack, void *element);
void *stack_peek(readapt_stack_t *stack);
void stack_pop(readapt_stack_t *stack);
void stack_free(readapt_stack_t *stack);

#endif
