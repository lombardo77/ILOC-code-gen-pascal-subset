/**********************************************
        CS415  Compilers  Project 2
**********************************************/
#include <stdio.h>
#include <stdlib.h>
#include "instrutil.h"
#include <string.h>



typedef struct var{
    int offset;
    char* data;
    struct var* next;
    int reg;
    int value;
    int type;
}var;

var* sym_table;

var* get_head() {
    return sym_table;
}

void resetRegs() {
    var* tmp = sym_table;
    while (tmp->next != NULL) {
        tmp->reg = -1;
        tmp = tmp->next;
    }
    tmp->reg = -1;
}

void init_symtable() {
    var* head = malloc(sizeof(var));
    head->data = "null";
    head->offset = 0;
    head->reg = -1;
    head->next = NULL;
    head->type = -1;
    head->value = -1;
    sym_table = head;
}

int find_offset(char* name, int type) {
    var* tmp = sym_table;
    while (tmp->next != NULL) {
        if (strcmp(tmp->data, name) == 0) {
            return tmp->offset;
        }
        tmp = tmp->next;
    }
    if (strcmp(tmp->data, name) == 0) 
        return tmp->offset;

    var* new_var = malloc(sizeof(var));
    new_var->offset = NextOffset();
    if (new_var->offset == 0) new_var->offset = NextOffset();
    new_var->data = name;
    new_var->reg = -1;
    new_var->type = type;
    new_var->value = -1;
    tmp->next = new_var;

    return new_var->offset;
}

int set_value(char* name, int value) {
    var* tmp = sym_table;
        while (tmp->next != NULL) {
            if (strcmp(tmp->data, name) == 0) {
                tmp->value = value;
                return 0;
            }
            tmp = tmp->next;
        }
        if (strcmp(tmp->data, name) == 0) { 
            tmp->value = value;
        }
        return 1;

}

int get_value(char* name) {
    var* tmp = sym_table;
    while (tmp->next != NULL) {
        if (strcmp(tmp->data, name) == 0) {
            return tmp->value;
        }
        tmp = tmp->next;
    }
    if (strcmp(tmp->data, name) == 0) {
        return tmp->value;
    }

    return -1;

}

int set_register(char* name, int regIn) {
    var* tmp = sym_table;
    while (tmp->next != NULL) {
        if (strcmp(tmp->data, name) == 0) {
            tmp->reg = regIn;
            return 0;
        }
        tmp = tmp->next;
    }
    if (strcmp(tmp->data, name) == 0) { 
        tmp->reg = regIn;
    }
    return 1;

}

int get_register(char* name) {
    var* tmp = sym_table;
    while (tmp->next != NULL) {
        if (strcmp(tmp->data, name) == 0) {
            return tmp->reg;
        }
        tmp = tmp->next;
    }
    if (strcmp(tmp->data, name) == 0) {
        return tmp->reg;
    }

    return -1;
}
