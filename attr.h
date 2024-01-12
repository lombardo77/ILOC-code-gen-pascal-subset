/**********************************************
			 CS415 Compilers Project 2
**********************************************/

#ifndef ATTR_H
#define ATTR_H

typedef union {int num; char *str;} tokentype;
typedef struct var_type {
    int type;
    char* list[100];
    int size;
    int array_len;
}var_type;

typedef struct  constant {
    int i_reg;
    int target_reg;
    int reg3;
    int true_label;
    int constant;
} constant;

typedef struct branch {
    int label;
}branch;

typedef struct {  
        int targetRegister;
        int targetRegister1;
        int r1;
        int r2;
        int constant;
        char* name;
        int inst;
        int label_true;
        int label_false;
        int label_after;
        int rvalue;
        } regInfo;

#endif


