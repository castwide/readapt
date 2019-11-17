#include <stdlib.h>
#include "stack.h"

#define STACK_CAPACITY 20

/**
 * Allocate a stack. The `elem_size` is the expected size of each element,
 * e.g., `sizeof(some_struct)`. The optional `free_func` argument is a pointer
 * to a function that will be called when an element is popped off the stack.
 */
readapt_stack_t *stack_alloc(size_t elem_size, void (*free_func)(void *))
{
    readapt_stack_t *s = malloc(sizeof(readapt_stack_t));
    s->elem_size = elem_size;
    s->free_func = free_func;
    s->size = 0;
    s->capacity = 0;
    return s;
}

/**
 * Add an element to the end of the stack
 */
void stack_push(readapt_stack_t *stack, void *element)
{
    if (stack->size == stack->capacity)
    {
        if (stack->capacity == 0)
        {
            stack->capacity = STACK_CAPACITY;
            stack->elements = malloc(stack->elem_size * stack->capacity);
        }
        else
        {
            stack->capacity += STACK_CAPACITY;
            stack->elements = realloc(stack->elements, stack->elem_size * stack->capacity);
        }
    }
    stack->elements[stack->size] = element;
    stack->size++;
}

/**
 * Get a pointer to the last element in the stack.
 */
void *stack_peek(readapt_stack_t *stack)
{
    return stack->size == 0 ? NULL : stack->elements[stack->size - 1];
}

/**
 * Pop the last element off the stack and pass it to free_func.
 */
void stack_pop(readapt_stack_t *stack)
{
    void *e;

    if (stack->size > 0)
    {
        e = stack->elements[stack->size - 1];
        if (stack->free_func)
        {
            stack->free_func(e);
        }
        // stack->elements[stack->size - 1] = NULL;
        stack->size--;
    }
}

/**
 * Free the stack from memory. If it still contains any elements, pass them to
 * free_func.
 */
void stack_free(readapt_stack_t *stack)
{
    int i;

    if (stack->free_func)
    {
        for (i = 0; i < stack->size; i++)
        {
            stack->free_func(stack->elements[i]);
        }
    }
    free(stack);
}
