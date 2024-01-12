%{
#include <stdio.h>
#include <stdlib.h>
#include "attr.h"
#include "instrutil.h"
#include "symtab.h"
int yylex();
void yyerror(char * s);

FILE *outfile;
char *CommentBuffer;
int curr_reg;
 
%}

%union {tokentype token;
        regInfo targetReg;
        constant constant;
        var_type var_type;
        branch branch;
        }

%token PROG PERIOD VAR 
%token INT BOOL ARRAY RANGE OF WRITELN THEN IF 
%token BEG END ASG DO FOR
%token EQ NEQ LT LEQ 
%token AND OR XOR NOT TRUE FALSE 
%token ELSE
%token WHILE
%token <token> ID ICONST 

%type <constant> integer_constant boolean_constant constant fstmt
%type <targetReg> exp lvalue rvalue condexp ifhead
%type <var_type> type idlist

%start program

%nonassoc EQ NEQ LT LEQ 
%left '+' '-' 
%left '*' 

%nonassoc THEN
%nonassoc ELSE

%%
program : {emitComment("Assign STATIC_AREA_ADDRESS to register \"r0\"");
           emit(NOLABEL, LOADI, STATIC_AREA_ADDRESS, 0, EMPTY); } 
           PROG ID ';' block PERIOD { }
	;

block	: variables cmpdstmt { }
	;

variables: /* empty */
	| VAR vardcls { }
	;

vardcls	: vardcls vardcl ';' { }
	| vardcl ';' { }
	| error ';' { yyerror("***Error: illegal variable declaration\n");}  
	;

vardcl	: idlist ':' type { 
                            
                            if (!$3.type) {
                                for (int j = 0; j < $1.size; j++) {
                                   find_offset($1.list[0], $3.type);
                                    for (int i = 0; i < $3.array_len; i ++)
                                       NextOffset(); 
                                    printf("%d ", $3.array_len);
                                }
                            }
                            else {
                                for (int i = 0; i < $1.size ; i ++) {
                                    find_offset($1.list[i], $3.type);

                                }
                            }
                            }
	;

idlist	: idlist ',' ID { 
                            $$.list[$$.size] = $3.str;
                            $$.size ++;
                        }
	| ID		{
                    $$.list[$$.size] = $1.str;
                    $$.size ++;
                }
	;

type : ARRAY '[' integer_constant RANGE integer_constant ']' OF stype 
     {
        $$.array_len = $5.constant;
        $$.type = 0;
     }
     | stype {
                $$.type = 1;
            }
     ;


stype : INT {}
      | BOOL {}
      ;

stmtlist : stmtlist ';' stmt { }
	| stmt { }
        | error { yyerror("***Error: illegal statement \n");}
	;

stmt    : ifstmt { }
	| wstmt { }
	| fstmt { }
	| astmt { }
	| writestmt { }
	| cmpdstmt { }
	;

cmpdstmt: BEG stmtlist END { }
	;

condexp	: exp NEQ exp		{ 
    }
	| exp EQ exp	{ 
                        int newReg = NextRegister();
                        emit(NOLABEL, CMPEQ, $1.targetRegister, $3.targetRegister, newReg);
                        $$.label_true = NextLabel();
                        $$.label_false = NextLabel();
                        $$.label_after = NextLabel();
                        emit(NOLABEL, CBR, newReg, $$.label_true, $$.label_false);

                    }
	| exp LT exp	{
                        int cur1 = get_register($1.name);
                        int cur2 = get_register($3.name);
                        int newReg = NextRegister();
                        $$.label_true = NextLabel();
                        $$.label_false = NextLabel();
                        $$.label_after = NextLabel();
                        emit(NOLABEL, CMPLT, $1.targetRegister, $3.targetRegister, newReg);
                        emit(NOLABEL, CBR, newReg, $$.label_true, $$.label_false);
                        $$.targetRegister = newReg;
                        $$.inst = CMPLT;
                        $$.r1 = cur1;
                        $$.r2 = cur2;
    
                    }
	| exp LEQ exp	{ }
    | ID    {
            int cur = get_register($1.str);
            int reg3 = NextRegister();
            if (cur != -1) {
                emit(NOLABEL, LOAD, cur, reg3, EMPTY);
                $$.targetRegister = reg3;
            }
            else {
                int reg_offset = find_offset($1.str, -1);
                int reg1 = NextRegister();
                int reg2 = NextRegister();
                emit(NOLABEL, LOADI, reg_offset, reg1, EMPTY);
                emit(NOLABEL, ADD, reg1, 0, reg2);
                emit(NOLABEL, LOAD, reg2, reg3, EMPTY);
                $$.targetRegister = reg3;
            }
            $$.name = $1.str;
            
            int newReg1 = NextRegister();
            int newReg2 = NextRegister();
            emit(NOLABEL, LOADI, 1, newReg1, EMPTY);
            emit(NOLABEL, CMPEQ, reg3, newReg1, newReg2);
            $$.label_true = NextLabel();
            $$.label_false = NextLabel();
            $$.label_after = NextLabel();
            emit(NOLABEL, CBR, newReg2, $$.label_true, $$.label_false);
                
            }
    | boolean_constant 
                        {
                        }
	| error { yyerror("***Error: illegal conditional expression\n");}  
        ;

ifstmt :  ifhead THEN stmt {
                             emit($1.label_false, NOP, EMPTY, EMPTY, EMPTY);
                            }
        | ifhead THEN stmt ELSE {
                                    emit(NOLABEL, BR, $1.label_after, EMPTY, EMPTY);
                                    emit($1.label_false, NOP, EMPTY, EMPTY, EMPTY);
                                    } stmt{  
                                    emit($1.label_after, NOP, EMPTY, EMPTY, EMPTY);
                                }
	;

ifhead : IF condexp {
                    emit($2.label_true, NOP, EMPTY, EMPTY, EMPTY);
                    $$.label_true = $2.label_true;
                    $$.label_false = $2.label_false;
                    $$.label_after = $2.label_after;
                    }
        ;

writestmt: WRITELN '(' exp ')' {
                                emit(NOLABEL, STOREAI, $3.targetRegister, 0, -4);
                                emit(NOLABEL, OUTPUT, 1020, EMPTY, EMPTY);
                                }
	;

wstmt	: WHILE  { }
          condexp { emit($3.label_true, NOP, EMPTY, EMPTY, EMPTY);}
          DO stmt   {
                        int newReg = NextRegister();
                        int reg1 = NextRegister();
                        int reg2 = NextRegister();
                        emit(NOLABEL, LOAD, $3.r1, reg1, EMPTY);
                        emit(NOLABEL, LOAD, $3.r2, reg2, EMPTY);
                        emit(NOLABEL, $3.inst, reg1, reg2, newReg);
                        emit(NOLABEL, CBR, newReg, $3.label_true, $3.label_false);
                        emit($3.label_false, NOP, EMPTY, EMPTY, EMPTY);
                        resetRegs();
                    }
	;


fstmt : FOR ID ASG constant ',' constant{
                                        int newReg1 = NextRegister();
                                        int newReg2 = NextRegister();
                                        int newReg3 = NextRegister();
                                        int true_label = NextLabel();
                                        int off_set = find_offset($2.str, -1);
                                        sprintf(CommentBuffer, "loading %s offset %d", $2.str, off_set);
                                        emitComment(CommentBuffer);
                                        emit(NOLABEL, LOADI, $4.constant, newReg1, EMPTY);
                                        emit(NOLABEL, LOADI, off_set, newReg2, EMPTY);
                                        emit(NOLABEL, ADD, newReg2, 0, newReg3);
                                        emit(NOLABEL, STORE, newReg1, newReg3, EMPTY);
                                        emit(NOLABEL, LOADI, $6.constant + 1, newReg2, EMPTY);
                                        emit(true_label, NOP, EMPTY, EMPTY, EMPTY);
                                        $4.i_reg = newReg1;
                                        $4.target_reg = newReg2;
                                        $4.true_label = true_label;
                                        $4.reg3 = newReg3;
                                        set_value($2.str, $4.constant);
                                        } DO stmt 
                                                {
                                                    emitComment("AFTER STMT");
                                                    int newReg = NextRegister();
                                                    int boolReg = NextRegister();
                                                    int false_label = NextLabel();
                                                    int true_label = $4.true_label;
                                                    emit(NOLABEL, LOADI, 1, newReg, EMPTY);
                                                    emit(NOLABEL, ADD, $4.i_reg, newReg, $4.i_reg);
                                                    emit(NOLABEL, STORE, $4.i_reg, $4.reg3, EMPTY);
                                                    emit(NOLABEL, CMPLT, $4.i_reg, $4.target_reg, boolReg);
                                                    emit(NOLABEL, CBR, boolReg, true_label, false_label);
                                                    emit(false_label, NOP, EMPTY, EMPTY, EMPTY);
                                                }
	;

astmt : lvalue ASG exp {
                        //int newReg = NextRegister(); 
                       // emit(NOLABEL, LOADI, $3.constant, $3.targetRegister, EMPTY);
                        emit(NOLABEL, STORE, $3.targetRegister, $1.targetRegister, EMPTY);
                        set_value($1.name, $3.constant);

                        
                        if (get_register($1.name) == -1) {
                            set_register($1.name, $1.targetRegister);
                        }
                        }
	;

lvalue	: ID {
                int reg_offset = find_offset($1.str, -1);
                int reg1 = NextRegister();
                int reg2 = NextRegister();

                sprintf(CommentBuffer, "loading %s into r%d", $1.str, reg2);
                emitComment(CommentBuffer);

                emit(NOLABEL, LOADI, reg_offset, reg1, EMPTY);
                emit(NOLABEL, ADD, reg1, 0, reg2);
                $$.targetRegister = reg2;
                $$.name = $1.str;
       }
        |  ID '[' exp ']' {
                
                int reg_offset = find_offset($1.str, -1) + ($3.constant - 1)*4;
                int reg1 = NextRegister();
                int reg2 = NextRegister();

                sprintf(CommentBuffer, "loading %s into offset %d", $1.str, reg_offset);
                emitComment(CommentBuffer);
                
                emit(NOLABEL, LOADI, reg_offset, reg1, EMPTY);
                emit(NOLABEL, ADD, reg1, 0, reg2);
                $$.targetRegister = reg2;
                $$.name = $1.str;
                //find_offset($1.str, -1) + ($3.constant - 1)*4;
                 
            }
        ;

rvalue : ID {
            int cur = get_register($1.str);
            int reg3 = NextRegister();
            if (cur != -1) {
                emit(NOLABEL, LOAD, cur, reg3, EMPTY);
                $$.targetRegister = reg3;
            }
            else {
                int reg_offset = find_offset($1.str, -1);
                int reg1 = NextRegister();
                int reg2 = NextRegister();
                emit(NOLABEL, LOADI, reg_offset, reg1, EMPTY);
                emit(NOLABEL, ADD, reg1, 0, reg2);
                emit(NOLABEL, LOAD, reg2, reg3, EMPTY);
                $$.targetRegister = reg3;
            }
            $$.name = $1.str;
            }
       | ID '[' exp ']' {
            int reg3 = NextRegister();
            int reg_offset = find_offset($1.str, -1) + ($3.constant - 1)*4;;
            int reg1 = NextRegister();
            int reg2 = NextRegister();
            emit(NOLABEL, LOADI, reg_offset, reg1, EMPTY);
            emit(NOLABEL, ADD, reg1, 0, reg2);
            emit(NOLABEL, LOAD, reg2, reg3, EMPTY);
            $$.targetRegister = reg3;
            $$.name = $1.str;

            }
       ;

exp	: rvalue { $$.name = $1.name;
                $$.constant = get_value($1.name);
                } 
    |exp '+' exp		{   int newReg = NextRegister();
                            $$.targetRegister = newReg;
                            emit(NOLABEL, ADD, $1.targetRegister, $3.targetRegister, newReg);
                            $$.constant = 77777;
                        }

    | exp '-' exp		{   int newReg = NextRegister(); 
                            $$.targetRegister = newReg;
                            emit(NOLABEL, SUB, $1.targetRegister, $3.targetRegister, newReg);
                                }

	| exp '*' exp		{   int newReg = NextRegister(); 
                            $$.targetRegister = newReg;
                            emit(NOLABEL, MULT, $1.targetRegister, $3.targetRegister, newReg);
                        }
    | exp AND exp   {
                        int newReg = NextRegister();
                        emit(NOLABEL, L_AND, $1.targetRegister, $3.targetRegister, newReg);
                        $$.targetRegister = newReg;
                    }
    | exp OR exp    {
                        int newReg = NextRegister();
                        emit(NOLABEL, L_OR, $1.targetRegister, $3.targetRegister, newReg);
                        $$.targetRegister = newReg;
                    }

    | exp XOR exp {}
    | NOT exp {}
    | '(' exp ')' {$$.targetRegister = $2.targetRegister;}
    | constant { 
                $$.targetRegister = curr_reg;
                emitComment("EMITTING LOADI FROM CONST");
                emit(NOLABEL, LOADI, $1.constant, $$.targetRegister, EMPTY);
                $$.constant = $1.constant;
                }
	| error { yyerror("***Error: illegal expression\n");}  
	;

constant : integer_constant { $$.constant = $1.constant;}
         | boolean_constant { $$.constant = $1.constant; }
         ;
integer_constant : ICONST {
                            int newReg = NextRegister();
                            //emit(NOLABEL, LOADI, $1.num, newReg, EMPTY);
                            curr_reg = newReg;
                            $$.constant = $1.num;
                    }
                 ;

boolean_constant : TRUE     { 
                                $$.constant = 1;
                                int newReg = NextRegister();
                                curr_reg = newReg;
                            }
                 | FALSE    { 
                                $$.constant = 0; 
                                int newReg = NextRegister();
                                curr_reg = newReg;

                            }
                 ;

%%

void yyerror(char* s) {
        fprintf(stderr,"%s\n",s);
	fflush(stderr);
        }

int main() {
    printf("\n          CS415 Project 2: Code Generator\n\n");
    init_symtable(); 
    outfile = fopen("iloc.out", "w");
    if (outfile == NULL) { 
        printf("ERROR: cannot open output file \"iloc.out\".\n");
        return -1;
    }

    CommentBuffer = (char *) malloc(500);  

    printf("1\t");
    yyparse();
    printf("\n");
  

    fclose(outfile);
  
    return 1;
}




