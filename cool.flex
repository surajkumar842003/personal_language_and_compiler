/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
#include<string.h>
#include <vector>

using namespace std;
string tmp="";

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */
int count=1;
extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
int comm = 0;
char previ = '*';
int sl=0;
extern YYSTYPE cool_yylval;
void toLowercase(char *str) {
    if (str == NULL) {
        fprintf(stderr, "Error: toLowercase received NULL pointer\n");
        return;
    }
    
    while (*str) {
        *str = tolower((unsigned char) *str);
        str++;
    }
}



%}


%x COMMENT 
%x STR
ID [a-zA-Z][a-zA-Z0-9_]*
NUM [0-9]+

DARROW          =>

%%
\-\-(.)* {/*IG*/}
"*)" { 
    int c;
    curr_lineno = count; 
   
        
    
        cool_yylval.error_msg = "Unmatched *)"; 
        return ERROR;
    
    }

 
"(*"   { comm=0; BEGIN(COMMENT); comm++; }





<COMMENT><<EOF>> { 
   cool_yylval.error_msg = "EOF in comment";
    BEGIN(INITIAL); 
  
 return ERROR;

}


<COMMENT>.|\n   { 
   
    if (previ == '(' && yytext[0] == '*') {
        comm++;  
    }
    if(yytext[0]=='\n') count++;
    previ = yytext[0];
}


<COMMENT>\*\)   { 
    comm--;  int c;
    if (comm < 0) {
        while ((c = yyinput()) != '\n' && c != EOF) {
        // Skip characters until a newline is found
        if(c=='\n') {count++, curr_lineno = count;}
            } 
    
    cool_yylval.error_msg = "Unmatched *)";
    BEGIN(INITIAL);
    return ERROR;
    
    }
    else if (comm == 0) { 
    
        BEGIN(INITIAL);
    } 
    
}

"<-" {return ASSIGN;}
"<=" {return LE; }

{DARROW}		{ return (DARROW); }

{ID} {
      static const char *keyword[] = {
          "class", "inherits", "new", "if", "then", "fi", "while",
          "loop", "pool", "let", "case", "isvoid", "in", "of", "not", "esac", "else"
      };

      static const int keyword_tokens[] = {
          CLASS, INHERITS, NEW, IF, THEN, FI, WHILE,
          LOOP, POOL, LET, CASE, ISVOID, IN, OF, NOT, ESAC, ELSE
      };

      char destination[101];

      strncpy(destination, yytext, 100);
      destination[100] = '\0'; // Ensure null termination
      toLowercase(destination);
      if (strcmp("true", destination) == 0 || strcmp("false", destination) == 0) {
              if (yytext[0] == 'f' || yytext[0] == 't') {
                  curr_lineno = count;
                  cool_yylval.boolean = (strcmp(destination, "true") == 0) ? 1 : 0;
              
                  return BOOL_CONST;
              } else {
                  cool_yylval.symbol = stringtable.add_string(yytext);
                  curr_lineno = count;
                  return TYPEID;
              }
          }
      
      for (int i = 0; i < 17; i++) {
          if (strcmp(keyword[i], destination) == 0) {
              curr_lineno = count;
              return keyword_tokens[i];
          }
      }
      if (isupper(yytext[0])) {
            curr_lineno = count;
            cool_yylval.symbol = stringtable.add_string(yytext);
            return TYPEID;
      }
      else if (strcmp(yytext, "SELF_TYPE") == 0 || strcmp(yytext, "self") == 0) {
          cool_yylval.symbol = stringtable.add_string(yytext);
          curr_lineno = count;
          return OBJECTID;
      } else {
          cool_yylval.symbol = stringtable.add_string(yytext);
          curr_lineno = count;
          return OBJECTID;
      }
}




\" { curr_lineno=count;BEGIN(STR);tmp=""; }

<STR><<EOF>> { 
    cool_yylval.error_msg = "EOF in string constant"; 
    BEGIN(INITIAL); 
    
 return ERROR; 
}
<STR>\\\n {
  tmp+="\n";}
<STR>\\t {tmp+="\t"; }
<STR>\\b {tmp+="\b"; }
<STR>\\f {tmp+="\f"; }
<STR>\\n {
    tmp+="\n";}

<STR>\\