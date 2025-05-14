%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

void yyerror(const char *s);
int yylex(void);

// Label generator
int label_count = 0;
char* output = NULL;

char* new_label() {
    char* label = malloc(10);
    sprintf(label, "L%d", label_count++);
    return label;
}

char* strjoin(const char* a, const char* b) {
    char* result = malloc(strlen(a) + strlen(b) + 2);
    strcpy(result, a);
    strcat(result, b);
    return result;
}

// Semantic symbol table
#define MAX_SYMBOLS 100
char* symbol_table[MAX_SYMBOLS];
int symbol_count = 0;
bool has_semantic_error = false;

bool is_defined(const char* var) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(symbol_table[i], var) == 0)
            return true;
    }
    return false;
}

void define_var(const char* var) {
    if (!is_defined(var)) {
        symbol_table[symbol_count++] = strdup(var);
    }
}
%}

%union {
    char* id;
    int num;
    char* op;
}

%token <id> ID
%token <num> NUMBER
%token <op> OP CMP

%token PRINT IF ELSE WHILE
%token ASSIGN SEMICOLON LPAREN RPAREN LBRACE RBRACE

%type <id> expr cond stmt block program

%%

program:
    program stmt   { output = strjoin(output, $2); }
  | stmt           { output = strjoin(output, $1); }
  ;

stmt:
    ID ASSIGN expr SEMICOLON {
        define_var($1);
        char temp[100];
        sprintf(temp, "%s = %s\n", $1, $3);
        $$ = strdup(temp);
    }
  | PRINT expr SEMICOLON {
        char temp[100];
        sprintf(temp, "print %s\n", $2);
        $$ = strdup(temp);
    }
  | IF LPAREN cond RPAREN block ELSE block {
        char* L1 = new_label();
        char* L2 = new_label();
        char* L3 = new_label();
        char* result = malloc(1000);
        sprintf(result,
            "if %s goto %s\n"
            "goto %s\n"
            "%s:\n%s"
            "goto %s\n"
            "%s:\n%s"
            "%s:\n",
            $3, L1, L2, L1, $5, L3, L2, $7, L3);
        $$ = result;
    }
  | WHILE LPAREN cond RPAREN block {
        char* Lstart = new_label();
        char* Lbody = new_label();
        char* Lend = new_label();
        char* result = malloc(1000);
        sprintf(result,
            "%s:\n"
            "if %s goto %s\n"
            "goto %s\n"
            "%s:\n%s"
            "goto %s\n"
            "%s:\n",
            Lstart, $3, Lbody, Lend, Lbody, $5, Lstart, Lend);
        $$ = result;
    }
  ;

block:
    LBRACE program RBRACE {
        $$ = output;
        output = strdup("");
    }
  ;

expr:
    expr OP expr {
        char* temp = malloc(32);
        sprintf(temp, "t%d", rand() % 1000);
        char buf[128];
        sprintf(buf, "%s = %s %s %s\n", temp, $1, $2, $3);
        output = strjoin(output, buf);
        $$ = temp;
    }
  | NUMBER {
        char* temp = malloc(32);
        sprintf(temp, "%d", $1);
        $$ = temp;
    }
  | ID {
        if (!is_defined($1)) {
            fprintf(stderr, "Semantic Error: variable '%s' used before assignment\n", $1);
            has_semantic_error = true;
        }
        $$ = strdup($1);
    }
  ;

cond:
    expr CMP expr {
        char* temp = malloc(64);
        sprintf(temp, "%s %s %s", $1, $2, $3);
        $$ = temp;
    }
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Syntax Error: %s\n", s);
}

int main() {
    output = strdup("");
    yyparse();
    if (!has_semantic_error)
        printf("%s", output);
    else
        fprintf(stderr, "\nCompilation failed due to semantic errors.\n");
    return 0;
}

