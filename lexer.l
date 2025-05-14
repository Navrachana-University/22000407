%{
#include "parser.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
%}

%%

"if"            { return IF; }
"else"          { return ELSE; }
"while"         { return WHILE; }
"print"         { return PRINT; }

[0-9]+          { yylval.num = atoi(yytext); return NUMBER; }

[a-zA-Z_][a-zA-Z0-9_]* {
                    yylval.id = strdup(yytext);
                    return ID;
                 }

"=="|"!="|"<="|">="|"<"|">" {
                    yylval.op = strdup(yytext);
                    return CMP;
                 }

"="             { return ASSIGN; }
";"             { return SEMICOLON; }
"("             { return LPAREN; }
")"             { return RPAREN; }
"{"             { return LBRACE; }
"}"             { return RBRACE; }

"+"|"-"|"*"|"/" {
                    yylval.op = strdup(yytext);
                    return OP;
                 }

[ \t\n\r]+      ;  // ignore whitespace

.               { printf("Unknown character: %s\\n", yytext); }

%%

int yywrap(void) {
    return 1;
}