%{
/******************************************************************************
 * FILENAME :                                                                 *
 *    email_catcher.lex                                                       *
 *                                                                            *
 * DESCRIPTION :                                                              *
 *    Gets email addresses from a file and save them in different formats     *
 *                                                                            *
 * AUTHOR :                                                                   *
 *    Copyright Luis Liñán (luislivilla at gmail.com) 2017                    *
 *                                                                            *
 * REPOSITORY :                                                               *
 *    https://github.com/lulivi/LEX_html_email_catcher                        *
 *                                                                            *
 * LICENSE :                                                                  *
 *    This program is free software: you can redistribute it and/or           *
 *    modify it under the terms of the GNU General Public License             *
 *    as published by the Free Software Foundation, version 3.                *
 *                                                                            *
 *    This program is distributed in the hope that it will be                 *
 *    useful, but WITHOUT ANY WARRANTY; without even the implied              *
 *    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR                 *
 *    PURPOSE. See the GNU General Public License for more details.           *
 *                                                                            *
 *    You should have received a copy of the GNU General Public License       *
 *    along with this program. If not, see <http://www.gnu.org/licenses/>     *
 ******************************************************************************/

/* ********************************* */
/* ********** Declarations ********* */
/* ********************************* */
#include <stdio.h>
#include <string.h>
#include <python2.7/Python.h>
#include <time.h>
#include <ctype.h>  // for IsNumeric
#include <stdlib.h>

int TAM;
int next;
char ** mails;
FILE * fpy;

int i, j;

time_t current_time;

/*
 * Returns true (non-zero) if character-string parameter represents a signed or
 * unsigned floating-point number. Otherwise returns false (zero).
 *
 * See http://rosettacode.org/wiki/Determine_if_a_string_is_numeric#C
 */
int IsNumeric (const char * s);

/*
 * Adds and item to "mails"
 */
void AddItem(char * new_element);

/*
 * Removes the text before the param "delim" from "prefix_mail"
 */
void RemovePrefix(char * prefix_mail, char delim);

/*
 * Displays all elements from the array "mails"
 */
void DisplayMails();

/*
 * Uses CPython to execute a python file for saving the mails to JSON format
 */
void WriteJSON();

/*
 * Deletes "mails" pointer
 */
void FreeMails();

%}

/* local-part */
outspch       ["!#$%&'*+-/=?^_`{|}~"]
out           {outspch}|[a-zA-Z0-9]
out_dot       "."{out}+
out_dot_1     {out}+{out_dot}*
quotspch      ["(),:;<>@\[\]."]|"////"|"//\""|" "
quot          \"[{quotspch}{outspch}a-zA-Z0-9]*\"

local         (({out_dot_1}+".")?{quot}("."{out_dot_1}+)?)|{out_dot_1}+

/* domain */

aA0           [a-zA-Z0-9]
aA0_hyph_dot  {aA0}+|"-"|"."
dom_hyph_dot  {aA0}+{aA0_hyph_dot}*{aA0}+

n             [0-9]
dom_ip        "\[IPv6:"({aA0}*|":")+"\]"|"\["{n}+"."{n}+"."{n}+"."{n}+"\]"

domain        {dom_hyph_dot}|{dom_ip}

/* address */

address       {local}"@"{domain}

/* elements */

tag1          a|abbr|address|area|article|aside|audio|b|base|bdi|bdo
tag2          blockquote|body|br|button|canvas|caption|cite|code|col
tag3          colgroup|data|datalist|dd|del|details|dfn|dialog|div|dl
tag4          dt|em|embed|fieldset|figcaption|figure|footer|form|h1|h2
tag5          h3|h4|h5|h6|head|header|hgroup|hr|html|i|iframe|img|input
tag6          ins|kbd|keygen|label|legend|li|link|main|map|mark|menu
tag7          menuitem|meta|meter|nav|noscript|object|ol|optgroup
tag8          option|output|p|param|pre|progress|q|rb|rp|rt|rtc|ruby
tag9          s|samp|script|section|select|small|source|span|strong
tag10         style|sub|summary|sup|table|tbody|td|template|textarea
tag11         tfoot|th|thead|time|title|tr|track|u|ul|var|video|wbr
tag12         acronym|applet|basefont|big|center|dir|font|frame|frameset
tag13         isindex|noframes|strike|tt

tag           (.*"<"({tag1}|{tag2}|{tag3}|{tag4}|{tag5}|{tag6}|{tag7}|{tag8}|{tag9}|{tag10}|{tag11}|{tag12}|{tag13})">")
%%

%{
/* ********************************* */
/* ********** Productions ********** */
/* ********************************* */
/*
*/
%}

{tag}                    {;}
^("mail="){address}      {RemovePrefix(yytext, '='); AddItem(yytext);}
{address}                {AddItem(yytext);}
.|\n                     {;}

%%

/* ********************************* */
/* ******** Additional Code ******** */
/* ********************************* */
int main (int argc, char *argv[]) {

  if (argc != 1){
    printf("Arguments: %s", argv[0]);
    exit(-1);
  }

  char input[255];
  char output[255];
  int json_choice = 0;
  char json_string[10];

  printf("Choose the input stream [ stdin(0) / path_to_file / ]: ");
  scanf("%s", &input);
  if(IsNumeric(input)) strcpy(input, "stdin");

  printf("Choose the output stream [ stdout(0) / path_to_file ]: ");
  scanf("%s", &output);
  if(IsNumeric(output)) strcpy(output, "stdout");

  printf("Do you want the output to be in json format? [ no(0) / yes(1) ]: ");
  scanf("%d", &json_choice);

  if(!strcmp(input, "stdin")) yyin = stdin;
  else
    if(!(yyin = fopen(input, "r"))){
      printf("Error opening input file.\n");
      exit(-1);
    }

  if(strcmp(output, "stdout")){
    if(!(yyout = fopen(output, "w"))){
      printf("Error opening output file.\n");
      exit(-1);
    }
  }
  else yyout = stdout;

  next = 0;
  TAM = 5;
  mails = (char**) malloc(20*sizeof(char*));
  for(i=0; i<TAM; ++i) mails[i] = (char*) malloc(255*sizeof(char));

  if(strcmp(input, "stdin")==0)
    printf("Enter the text (Ctrl+D to finish):\n\n");

  yylex ();

  if(!strcmp(output, "stdout"))
    fprintf(yyout, "\n\n");

  if(json_choice){
    AddItem(output);
    WriteJSON();
  }
  else
    DisplayMails();

  FreeMails();

  return 0;
}

// ====================================

// Returns 0 if string is not a signed or unsigned floating-point number.
int IsNumeric (const char * s) {
  if (s == NULL || *s == '\0' || isspace(*s))
    return 0;
  char * p;
  strtod (s, &p);
  return *p == '\0';
}

// ====================================

void AddItem(char  *new_element){
  if(next >= TAM){
    TAM = TAM * sizeof * mails;
    mails = (char**)realloc(mails, sizeof * mails * TAM);
    for(i=next; i<TAM; ++i) mails[i] = (char*) malloc(255*sizeof(char));
  }
  strcpy(mails[next], new_element);
  ++next;
}

// ====================================

void RemovePrefix(char * prefix_mail, char delim){
  char * substr = strchr(prefix_mail, delim);
  strcpy(prefix_mail, substr+1);
}

// ====================================

void DisplayMails(){
  time_t rawtime;
  struct tm * timeinfo;

  time(&rawtime);
  timeinfo = localtime(&rawtime);

  fprintf(yyout, "%s\n\nE-Mails:\n", asctime (timeinfo) );
  for(i=0; i<next; ++i) fprintf(yyout, "%s\n", mails[i]);
}

// ====================================
void WriteJSON(){
  Py_SetProgramName("pySON");
  Py_Initialize();
  PySys_SetArgv(next, mails);
  fpy = fopen("pySON.py","r");
  PyRun_SimpleFile(fpy, "pySON.py");
  fclose(fpy);
  Py_Finalize();
}

// ====================================

void FreeMails(){
  for(i=0; i<TAM; ++i) free(mails[i]);
  free(mails);
}
