#ifndef STACK_H_
#define STACK_H_

#include "stddef.h"

typedef struct stack_struct {
    int size;
    size_t elem_size;
    void (*free_func)(void *);
    int capacity;
    void **elements;
} stack_t;

stack_t *stack_alloc(size_t elem_size, void(*free_func)(void*));
void stack_push(stack_t *stack, void *element);
void *stack_peek(stack_t *stack);
void stack_pop(stack_t *stack);
void stack_free(stack_t *stack);

#endif
