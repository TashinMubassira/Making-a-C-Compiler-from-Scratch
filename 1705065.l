%option noyywrap yylineno

%{
#include<bits/stdc++.h>
#include<fstream>

using namespace std;

#include "SymbolTable.h"
#include "y.tab.h"

extern YYSTYPE yylval;
extern SymbolTable *table;
void yyerror(char *);

int line_count=1;
int error_count = 0;

%}


WHITESPACE [ \t\f\r\v]+
delim [ \t\r\f\v] 
LETTER [a-zA-Z]
ALPHANUMERIC [a-zA-Z0-9]
IDENTIFIER [a-zA-Z_][a-zA-Z0-9_]*
DIGIT [0-9]
VALID_FRACTION ({DIGIT}*[.]{DIGIT}+)|({DIGIT}*[.]{DIGIT}+[Ee][-]?{DIGIT}+)|({DIGIT}+[Ee][-]?{DIGIT}+)
ILL_FORMED_NUMBER ({DIGIT}*[.]{DIGIT}+[Ee][-]?{VALID_FRACTION}+)|({DIGIT}+[Ee][-]?{VALID_FRACTION}+)
INVALID_SUFFIX_ERROR  ({DIGIT}|{VALID_FRACTION}|{ILL_FORMED_NUMBER})+{IDENTIFIER}({VALID_FRACTION}|{ILL_FORMED_NUMBER})*
INVALID_PREFIX_ERROR  ({DIGIT}|{VALID_FRACTION}|{ILL_FORMED_NUMBER})*{IDENTIFIER}({VALID_FRACTION}|{ILL_FORMED_NUMBER})+ 
INVALID_SUFFIX_OR_PREFIX_ERROR {INVALID_SUFFIX_ERROR}+|{INVALID_PREFIX_ERROR}+
NEWLINE \n

%%
{WHITESPACE} {}
{NEWLINE}   {   line_count++;       }
"if"        {   return IF;          }
"else"      {   return ELSE;        }
"for"       {   return FOR;         }
"do"        {   return DO;          }
"int"       {   return INT;         }
"float"     {   return FLOAT;       }
"void"      {   return VOID;        }
"switch"    {   return SWITCH;      }
"default"   {   return DEFAULT;     }
"while"     {   return WHILE;       }
"break"     {   return BREAK;       }
"char"      {   return CHAR;        }
"double"    {   return DOUBLE;      }
"return"    {   return RETURN;      }
"case"      {   return CASE;        }
"continue"  {   return CONTINUE;    }
"println"    {   return PRINTLN;     }

"+"     |
"-"     {
            SymbolInfo *s= new  SymbolInfo(yytext, "ADDOP");
            yylval.symbol = s;
            return ADDOP;           
        }

"*"     |
"/"     |
"%"     {
            SymbolInfo *s= new  SymbolInfo(yytext, "MULOP");
            yylval.symbol = s;
            return MULOP;
        }

"++"        {   return INCOP;   }
"--"        {   return DECOP;   }

"<"         |
"<="        |   
">"         |
">="        |
"=="        |
"!="        {
            SymbolInfo *s= new  SymbolInfo(yytext, "RELOP");
            yylval.symbol = s;
            return RELOP;
        }

"="     {   return ASSIGNOP;        }

"&&"        |
"||"        {
            SymbolInfo *s= new  SymbolInfo(yytext, "LOGICOP");
            yylval.symbol = s;
            return LOGICOP;
        }


"!"     {   return NOT; }


"("     {   return LPAREN;  }
")"     {   return RPAREN;  }

"{"     {   return LCURL;   }
"}"     {   return RCURL;   }

"["     {   return LTHIRD;  }
"]"     {   return RTHIRD;  }


","     {   return COMMA;       }
";"     {   return SEMICOLON;   }


{DIGIT}+    {
            SymbolInfo *s = new  SymbolInfo(yytext,"CONST_INT");
            yylval.symbol = s;
            return CONST_INT;
        }


{VALID_FRACTION}    {
                SymbolInfo *s = new  SymbolInfo(yytext,"CONST_FLOAT");
                yylval.symbol = s;
                return CONST_FLOAT; 
            }                                        


[a-zA-Z_][a-zA-Z0-9_]* {    
                SymbolInfo *s= new  SymbolInfo(yytext,"ID");
                yylval.symbol = s;           
                return ID;
            }


%%



