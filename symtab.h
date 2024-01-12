/**********************************************
        CS415  Compilers  Project 2
**********************************************/

#ifndef SYMTAB_H
#define SYMTAB_H

typedef struct var{
    int offset;
    char* data;
    struct var* next;
    int reg;
    int value;
    int type;
}var;

void resetRegs();
var* get_head();
void init_symtable();
int find_offset(char* name, int type); 
int get_register(char* name);
void set_register(char* name, int regIn);
int get_value(char* name);
void set_value(char* name, int value);


#endif
