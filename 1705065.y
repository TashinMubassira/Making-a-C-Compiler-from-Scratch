%{
#include<bits/stdc++.h>
#include<fstream>

using namespace std;

#include "SymbolTable.h"

int yyparse(void);
int yylex(void);
extern FILE *yyin;
extern int line_count;
extern int error_count;

int tempCount = 0;
int labelCount = 0;

string voidCheck;

SymbolTable Symbol_table(7);

FILE* fp;
ofstream log_output;
ofstream error_output;
ofstream code_output;
//ofstream optimised_code_output;

parameter single_parameter;

vector<SymbolInfo*> variable_list;
vector<string> all_variable_list;
vector<parameter> ParameterList;
vector<parameter> arg_list;
vector<string> all_function_list;
vector<string> argument_ashol_name;

string current_func_return_label = "";
string main_return_label = "";

/*
void optimization(){
    code_output.open("code.asm");

    if (code_output.is_open()){   
      while(getline(code_output, line)){ 
        
      }
      code_output.close(); 
   }
}
*/

void insert_variable(SymbolInfo* symbol){
    SymbolInfo *variable = new SymbolInfo(symbol->get_name(), "ID");
    variable->return_type = symbol->return_type;
    variable->size = symbol->size;

    Symbol_table.Insert(variable);
    
    return;
}

bool func_checking(SymbolInfo* duplicate, SymbolInfo* original, string returnType)
{
    bool valid_function = true;
    if(duplicate->return_type != returnType)
    {
        log_output << "Error at line no " << line_count << ": Return type mismatch with function declaration in function " << original->get_name() << "\n" << endl;
        error_output << "Error at line no " << line_count << ": Return type mismatch with function declaration in function " << original->get_name() << "\n" << endl;
        error_count++;
        valid_function = false;
    }

    if(duplicate->parameter_list.size() == original->parameter_list.size())
    {
        for(int i = 0; i < duplicate->parameter_list.size(); i++)
        {
            if(duplicate->parameter_list[i].parameter_type != original->parameter_list[i].parameter_type)
            {
                log_output << "Error at line no " << line_count << ": " << i+1 << "th argument mismatch in function " << original->get_name() << "\n" << endl;
                error_output << "Error at line no " << line_count << ": " << i+1 << "th argument mismatch in function " << original->get_name() << "\n" << endl;
                error_count++;
                valid_function = false; 
            }
        }
    }

    else
    {
        error_output << original->get_name() << " " << original->parameter_list.size() << endl;
        log_output << "Error at line no " << line_count << ": Total number of arguments mismatch with declaration in function " << original->get_name() << "\n" << endl;
        error_output << "Error at line no " << line_count << ": Total number of arguments mismatch with declaration in function " << original->get_name() << "\n" << endl;
        error_count++;
        valid_function = false;   
    }

    return valid_function;
}

void yyerror(char *s)
{
    log_output << "Line no " << line_count << s << endl;
}

string newTemp() {
    string ret = "t" + to_string(tempCount);
    tempCount++;
    all_variable_list.push_back(ret + " dw ?");
    return ret;
}

string newLabel(){
    string ret = "Label" + to_string(labelCount);
    labelCount++;
    return ret;
}

string mov(string x, string y){
    return "MOV " + x + ", " + y + "\n"; 
}

string comment_writing(string cmt){
    return "; " + cmt + "\n";
}

%}

%union{
    SymbolInfo *symbol;
}

%token IF ELSE FOR DO INT FLOAT VOID SWITCH DEFAULT WHILE BREAK 
%token CHAR DOUBLE RETURN CASE CONTINUE MAIN PRINTLN
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD 
%token COMMA SEMICOLON 
%token CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        log_output << "Line " << line_count - 1 << ": start : program" << "\n"  << endl;

        Symbol_table.PrintAllScopeTable(log_output);
        log_output << "Total lines: " << line_count - 1 << endl;
        log_output << "Total errors: " << error_count << endl;

        code_output << ".MODEL SMALL " << endl << endl;
        code_output << ".STACK 100h " << endl << endl << endl;
        code_output << ".DATA \n" << endl << endl;
        code_output << "CR EQU 0DH" << endl;
        code_output << "LF EQU 0AH" << endl << endl;
        code_output << "NEWLINE DB CR, LF,'$'" << endl;
        for(int i = 0; i < all_variable_list.size(); i++){
            code_output << all_variable_list[i] << endl; 
        }
        code_output << ".CODE " << endl << endl;
        code_output << "MAIN PROC " << endl;
        code_output << "mov ax, @data " << endl;
        code_output << "mov ds, ax " << endl;
        code_output << $<symbol>1->code << endl;
        code_output <<  main_return_label + ": " << endl;
        code_output << ";DOS EXIT" << endl;
        code_output << "MOV AH, 4CH" << endl;
        code_output << "INT 21H" << endl;
        code_output << "MAIN ENDP " << endl;
        string line;
        ifstream printfile ("PRINT PROC.txt");
        if (printfile.is_open())
        {
            while (getline (printfile,line))
            {
                code_output << line << '\n';
            }
            printfile.close();
        }
        for(int i = 0; i < all_function_list.size(); i++){
            code_output << all_function_list[i] << endl; 
        }
        code_output << "END MAIN " << endl;
    }
    ;

program : program unit 
        {
            string str = $<symbol>1->get_name() + "\n" + $<symbol>2->get_name();
            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");
            log_output << "Line " << line_count << ": program : program unit" << "\n" << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->code = $<symbol>1->code + $<symbol>2->code;;
        }
    | unit
        {
            string str = $<symbol>1->get_name();
            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");
            log_output << "Line " << line_count << ": program : unit" << "\n" << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->code = $<symbol>1->code;
        }
    ;
    
unit : var_declaration
        {
            string str = $<symbol>1->get_name();
            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");
            log_output << "Line " << line_count << ": unit : var_declaration" << "\n" << endl;
            log_output << str << "\n" << endl;
        }
        | func_declaration
        {
            string str = $<symbol>1->get_name();
            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");
            log_output << "Line " << line_count << ": unit : func_declaration" << "\n" << endl;
            log_output << str << "\n" << endl;
        }
        | func_definition
        {
            string str = $<symbol>1->get_name();
            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");
            log_output << "Line " << line_count << ": unit : func_definition" << "\n" << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->code = $<symbol>1->code;
        }
        ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
        {
            string str = $<symbol>1->get_name() + " ";
            str += $<symbol>2->get_name() + "(";
            str += $<symbol>4->get_name() + ")" + ";" ;

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON" << "\n" << endl;
            log_output << str << "\n" << endl;

            if(Symbol_table.Insert($<symbol>2) == false)
            {
                log_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                error_count++;
            }

            else
            {
                $<symbol>2->size = -2;
                $<symbol>2->return_type = $<symbol>1->get_name();
                
                for(int i = 0; i < ParameterList.size(); i++)
                {
                    single_parameter.parameter_type = ParameterList[i].parameter_type;
                    single_parameter.parameter_name = ParameterList[i].parameter_name;
                    ($<symbol>2)->parameter_list.push_back(single_parameter);
                }
                
            }

            for(int i = 0; i < ParameterList.size();i++)
            {
                for(int j = i + 1; j < ParameterList.size(); j++)
                {
                    if(ParameterList[i].parameter_name == ParameterList[j].parameter_name)
                    {
                        log_output << "Function declaration theke print hocche" << endl;
                        log_output << "Error at line no " << line_count << ": Multiple declaration of " << ParameterList[i].parameter_name << " in parameter" << "\n" << endl;
                        error_output << "Error at line no " << line_count << ": Multiple declaration of " << ParameterList[i].parameter_name << " in parameter" << "\n" << endl;
                        error_count++;
                    }
                }
            }
            ParameterList.clear();

        }
        | type_specifier ID LPAREN RPAREN SEMICOLON
        {
            string str = $<symbol>1->get_name() + " ";
            str += $<symbol>2->get_name() + "(" + ")" + ";";

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON" << "\n" << endl;
            log_output << str << "\n" << endl;

            if(Symbol_table.Insert($<symbol>2) == false)
            {
                log_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                error_count++;
            }

            else
            {
                $<symbol>2->size = -2;
                $<symbol>2->return_type = $<symbol>1->get_name();

            }
        }
        ;
         
func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement
        {
            for(int i = 0; i < ParameterList.size(); i++)
            {
                log_output << ParameterList[i].parameter_name << " " << ParameterList[i].parameter_type << endl;
            }

            string str = $<symbol>1->get_name() + " ";
            str += $<symbol>2->get_name() + "(";
            str += $<symbol>4->get_name() + ")";
            str += $<symbol>6->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement" << "\n" << endl;
            log_output << str << "\n" << endl;

            if($<symbol>1->get_name() != $<symbol>6->return_type)
            {
                log_output << "Error at line no " << line_count << ": Return type mismatch with function definition in function " << $<symbol>2->get_name() << "\n" << endl;
                error_output << "Error at line no " << line_count << ": Return type mismatch with function definition in function " << $<symbol>2->get_name() << "\n" << endl;
                error_count++;

            }

            if(Symbol_table.Insert($<symbol>2) == true)
            {
                $<symbol>2->size = -3;
                $<symbol>2->return_type = $<symbol>1->get_name();

                for(int i = 0; i < ParameterList.size(); i++)
                {
                    single_parameter.parameter_type = ParameterList[i].parameter_type;
                    single_parameter.parameter_name = ParameterList[i].parameter_name;
                    ($<symbol>2)->parameter_list.push_back(single_parameter);
                }
            }

            else
            {
                SymbolInfo *duplicate = Symbol_table.Lookup($<symbol>2->get_name());

                if(duplicate->size != -2)
                {
                    log_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                    error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                    error_count++;
                }

                else
                {
                    //declaration and definition both kora ase 

                    $<symbol>2->size = -3;
                    $<symbol>2->return_type = $<symbol>1->get_name();

                    for(int i = 0; i < ParameterList.size(); i++)
                    {
                        single_parameter.parameter_type = ParameterList[i].parameter_type;
                        single_parameter.parameter_name = ParameterList[i].parameter_name;
                        ($<symbol>2)->parameter_list.push_back(single_parameter);
                    }

                    if(func_checking(duplicate, $<symbol>2 ,$<symbol>1->get_name()))
                    {
                        duplicate->size = -3;
                    }

                }
            }    
                if(current_func_return_label == ""){
                    current_func_return_label = newLabel();
                }

                string function_proc_asm = $<symbol>2->get_name() + " PROC " + "NEAR \n";
                function_proc_asm += "PUSH BP \n"; 
                function_proc_asm += mov("BP","SP");
                function_proc_asm += $<symbol>6->code;
                function_proc_asm += current_func_return_label + ": \n";
                function_proc_asm += "POP BP \n";
                function_proc_asm += "RET " + to_string(ParameterList.size()*2) + "\n";
                function_proc_asm +=  $<symbol>2->get_name() + " ENDP \n";

                all_function_list.push_back(function_proc_asm);

                ParameterList.clear();
                current_func_return_label.clear();        

        }
        | type_specifier ID LPAREN RPAREN compound_statement
        {
            string str = $<symbol>1->get_name() + " ";
            str += $<symbol>2->get_name() + "(" + ")" + $<symbol>5->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": func_definition : type_specifier ID LPAREN RPAREN compound_statement" << "\n" << endl;
            log_output << str << "\n" << endl;

            if($<symbol>1->get_name() != $<symbol>5->return_type)
            {
                log_output << "Error at line no " << line_count << ": Return type mismatch with function definition in function " << $<symbol>2->get_name() << "\n" << endl;
                error_output << "Error at line no " << line_count << ": Return type mismatch with function definition in function " << $<symbol>2->get_name() << "\n" << endl;
                error_count++;

            }

            if(Symbol_table.Insert($<symbol>2) == true)
            {
                $<symbol>2->size = -3;
                $<symbol>2->return_type = $<symbol>1->get_name();
            }

            else
            {
                SymbolInfo *duplicate = Symbol_table.Lookup($<symbol>2->get_name());

                if(duplicate->size != -2)
                {
                    log_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                    error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>2->get_name() << "\n" << endl;
                    error_count++;
                }

                else
                {
                    //declaration and definition both kora ase 
                    $<symbol>2->size = -3;
                    $<symbol>2->return_type = $<symbol>1->get_name();

                    for(int i = 0; i < ParameterList.size(); i++)
                    {
                        single_parameter.parameter_type = ParameterList[i].parameter_type;
                        single_parameter.parameter_name = ParameterList[i].parameter_name;
                        ($<symbol>2)->parameter_list.push_back(single_parameter);
                    }

                    if(func_checking(duplicate, $<symbol>2 ,$<symbol>1->get_name()))
                    {
                        duplicate->size = -3;
                    }

                }
            }


            string new_label = newLabel();

            if(current_func_return_label == ""){
                current_func_return_label = newLabel();
            }

            if($<symbol>2->get_name() != "main"){
                string function_proc_asm = $<symbol>2->get_name() + " PROC " + "NEAR \n";
                function_proc_asm += "PUSH BP \n"; 
                function_proc_asm += mov("BP","SP");
                function_proc_asm += $<symbol>5->code;
                function_proc_asm += current_func_return_label + ": \n";
                function_proc_asm += "POP BP \n";
                function_proc_asm +=  $<symbol>2->get_name() + " ENDP \n";

                all_function_list.push_back(function_proc_asm);
            }

            else{
                $<symbol>$->code = $<symbol>5->code;
                main_return_label = current_func_return_label;
            }

            current_func_return_label.clear();
        }
        ;               


parameter_list  : parameter_list COMMA type_specifier ID
        {
            string str = $<symbol>1->get_name();
            str += "," + $<symbol>3->get_name() + " ";
            str += $<symbol>4->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": parameter_list : parameter_list COMMA type_specifier ID" << "\n" << endl;
            log_output << str << "\n" << endl;

            single_parameter.parameter_type = $<symbol>3->get_name();

            if(single_parameter.parameter_type == "void")
            {
                log_output << "Error at line " << line_count << ": Parameter type cannot be void " << "\n" << endl;
                error_output << "Error at line " << line_count << ": Parameter type cannot be void " << "\n" << endl;
                error_count++;

                single_parameter.parameter_type = "voidCheck";
            }

            single_parameter.parameter_name = $<symbol>4->get_name();
            ParameterList.push_back(single_parameter);
        }
        | parameter_list COMMA type_specifier
        {
            string str = $<symbol>1->get_name();
            str += "," + $<symbol>3->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": parameter_list : parameter_list COMMA type_specifier" << "\n" << endl;
            log_output << str << "\n" << endl;

            single_parameter.parameter_type = $<symbol>3->get_name();
            single_parameter.parameter_name = "";

            ParameterList.push_back(single_parameter);
        }
        | type_specifier ID
        {
            string str = $<symbol>1->get_name() + " ";
            str += $<symbol>2->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": parameter_list : type_specifier ID" << "\n" << endl;
            log_output << str << "\n" << endl;

            single_parameter.parameter_type = $<symbol>1->get_name();

            if(single_parameter.parameter_type == "void")
            {
                log_output << "Error at line " << line_count << ": Parameter type cannot be void " << "\n" << endl;
                error_output << "Error at line " << line_count << ": Parameter type cannot be void " << "\n" << endl;
                error_count++;

                single_parameter.parameter_type = "voidCheck";
            }

            single_parameter.parameter_name = $<symbol>2->get_name();
            ParameterList.push_back(single_parameter);
        }
        | type_specifier
        {
            string str = $<symbol>1->get_name();

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": parameter_list : type_specifier" << "\n" << endl;
            log_output << str << "\n" << endl;

            single_parameter.parameter_type = $<symbol>1->get_name();
            single_parameter.parameter_name = "";

            ParameterList.push_back(single_parameter);
        }
        ;

        
compound_statement : LCURL embedded_enter_scope statements RCURL
        {
            string str = "{\n" + $<symbol>3->get_name() + "\n}";

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": compound_statement : LCURL statements RCURL" << "\n" << endl;
            log_output << str << "\n" << endl;

            Symbol_table.PrintAllScopeTable(log_output);
            Symbol_table.ExitScope();

            $<symbol>$->return_type = $<symbol>3->return_type;


            $<symbol>$->code = $<symbol>3->code;
            $<symbol>$->ashol_name = $<symbol>3->ashol_name;
        }
        | LCURL embedded_enter_scope RCURL
        {
            string str = "{}" ;

            $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

            log_output << "Line " << line_count << ": compound_statement : LCURL RCURL" << "\n" << endl;
            log_output << str << "\n" << endl;

            Symbol_table.PrintAllScopeTable(log_output);
            Symbol_table.ExitScope();

            $<symbol>$->return_type = "void";
        }
        ;

embedded_enter_scope: {
                        Symbol_table.EnterScope();

                        // parameter list er variable gula ke insert korbo 

                        for(int i = 0; i < ParameterList.size(); i++)
                        {
                            SymbolInfo *temp_symbol = new SymbolInfo();
                            temp_symbol->set_name(ParameterList[i].parameter_name);
                            temp_symbol->set_type("ID");
                            temp_symbol->return_type = ParameterList[i].parameter_type;
                            temp_symbol->size = -1;
                            temp_symbol->ashol_name = "[BP + " + to_string(4+(((ParameterList.size() - 1) - i) * 2)) + "]";

                            if(Symbol_table.Insert(temp_symbol) == false)
                            {
                                log_output << "Error at line no " << line_count << ": Multiple declaration of " << ParameterList[i].parameter_name << " in parameter" << "\n" << endl;
                                error_output << "Error at line no " << line_count << ": Multiple declaration of " << ParameterList[i].parameter_name << " in parameter" << "\n" << endl;
                                error_count++;
                            }
                        }
                }
                ;        
            
var_declaration : type_specifier declaration_list SEMICOLON
                {
                    string str = $<symbol>1->get_name() + " ";
                    str += $<symbol>2->get_name() + ";" ;

                    $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

                    log_output << "Line " << line_count << ": var_declaration : type_specifier declaration_list SEMICOLON" << "\n" << endl;

                    if($<symbol>1->get_name() == "void")
                    {
                        log_output << "Error at line " << line_count << ": Variable type cannot be void " << "\n" << endl;
                        error_output << "Error at line " << line_count << ": Variable type cannot be void " << "\n" << endl;
                        error_count++;

                    }

                    log_output << str << "\n" << endl;

                    if($<symbol>1->get_name() == "int")
                    {
                        for(int i = 0; i < variable_list.size();i++)
                        {
                            variable_list[i]->return_type = "int";
                            insert_variable(variable_list[i]);
                        }
                    }

                    else
                    {
                        for(int i = 0; i < variable_list.size();i++)
                        {
                            variable_list[i]->return_type = "float";
                            insert_variable(variable_list[i]);
                        }
                
                    }

                    variable_list.clear();
                }
                ;
         

type_specifier  : INT { 
                        $<symbol>$ = new SymbolInfo("int","NON_TERMINAL");

                        log_output << "Line " << line_count << ": type_specifier : INT" << "\n"  << endl;
                        log_output << "int" << "\n" << endl; 
                      }
                | FLOAT { 
                            $<symbol>$ = new SymbolInfo("float","NON_TERMINAL");

                            log_output << "Line " << line_count << ": type_specifier : FLOAT" << "\n"  << endl;
                            log_output << "float" << "\n" << endl;
                        }
                | VOID  { 
                            $<symbol>$ = new SymbolInfo("void","NON_TERMINAL");

                            log_output << "Line " << line_count << ": type_specifier : VOID" << "\n"  << endl; 
                            log_output << "void" << "\n" << endl;   
                        }
                ;
 
 declaration_list : declaration_list COMMA ID
                {   
                    $<symbol>$ = new SymbolInfo(($<symbol>1)->get_name() + "," + ($<symbol>3)->get_name(), "NON_TERMINAL");

                    //this is a variable variable
                    ($<symbol>3)->size = -1;
                    variable_list.push_back($<symbol>3);
                    all_variable_list.push_back(($<symbol>3)->get_name() + Symbol_table.GetCurrentScopeTable()->get_unique_id() + " dw" + " ?");

                    if(Symbol_table.Insert($<symbol>3) == false)
                    {
                        log_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>3->get_name() << "\n" << endl;
                        error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>3->get_name() << "\n" << endl;
                        error_count++;
                    }

                    log_output << "Line " << line_count << ": declaration_list : declaration_list COMMA ID" << "\n"  << endl;
                    log_output << ($<symbol>1)->get_name() << "," << ($<symbol>3)->get_name() << "\n" <<endl;  

                }
                | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                {
                    string str = $<symbol>1->get_name();
                    str += ",";
                    str += $<symbol>3->get_name();
                    str += "[" + $<symbol>5->get_name() + "]";

                    $<symbol>$ = new SymbolInfo(str,"NON_TERMINAL");

                    //this is an array
                    ($<symbol>3)->size = 0;
                    string size_str = ($<symbol>5)->get_name();
                    stringstream size_int(size_str);
                    size_int >> ($<symbol>3)->size;

                    variable_list.push_back($<symbol>3);
                    all_variable_list.push_back(($<symbol>3)->get_name() + Symbol_table.GetCurrentScopeTable()->get_unique_id() + " dw " + size_str + " dup(?)");

                    if(Symbol_table.Insert($<symbol>3) == false)
                    {
                        log_output << "Error at line " << line_count << ": Multiple declaration of " << $<symbol>3->get_name() << "\n" << endl;
                        error_output << "Error at line " << line_count << ": Multiple declaration of " << $<symbol>3->get_name() << "\n" << endl;
                        error_count++;
                    } 

                    log_output << "Line " << line_count << ": declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD" << "\n"  << endl;  
                    log_output << str << "\n" <<endl;
 
                }
                | ID
                {
                    $<symbol>$ = new SymbolInfo(($<symbol>1)->get_name(), "NON_TERMINAL");

                    ($<symbol>1)->size = -1;
                    variable_list.push_back($<symbol>1);
                    all_variable_list.push_back(($<symbol>1)->get_name() + Symbol_table.GetCurrentScopeTable()->get_unique_id() + " dw ?");

                    if(Symbol_table.Insert($<symbol>1) == false)
                    {
                        log_output << "Error at line " << line_count << ": Multiple declaration of " << $<symbol>1->get_name() << "\n" << endl;
                        error_output << "Error at line no " << line_count << ": Multiple declaration of " << $<symbol>1->get_name() << "\n" << endl;
                        error_count++;
                    }  

                    log_output << "Line " << line_count << ": declaration_list : ID" << "\n"  << endl;
                    log_output << ($<symbol>1)->get_name() << "\n" << endl;
  

                }
                | ID LTHIRD CONST_INT RTHIRD
                {
                    string str = ($<symbol>1)->get_name();
                    str += "[" + $<symbol>3->get_name() + "]";

                    $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

                    //this is an array
                    ($<symbol>1)->size = 0;
                    string size_str = ($<symbol>3)->get_name();
                    stringstream size_int(size_str);
                    size_int >> ($<symbol>3)->size;

                    variable_list.push_back($<symbol>1);
                    all_variable_list.push_back(($<symbol>1)->get_name() + Symbol_table.GetCurrentScopeTable()->get_unique_id() + " dw " + size_str + " dup(?)");

                    if(Symbol_table.Insert($<symbol>1) == false)
                    {
                        log_output << "Error at line " << line_count << ": Multiple declaration of " << $<symbol>1->get_name() << "\n" << endl;
                        error_output << "Error at line " << line_count << ": Multiple declaration of " << $<symbol>1->get_name() << "\n" << endl;
                        error_count++;
                    } 

                    log_output << "Line " << line_count << ": declaration_list : ID LTHIRD CONST_INT RTHIRD" << "\n"  << endl;
                    log_output << str << "\n" << endl; 
                }
                ;
          
statements : statement
            {
                string str = ($<symbol>1)->get_name();

                $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

                log_output << "Line " << line_count << ": statements : statement" << "\n"  << endl;
                log_output << str << "\n" << endl;

                $<symbol>$->return_type = $<symbol>1->return_type;


                $<symbol>$->code = $<symbol>1->code;
                $<symbol>$->ashol_name = $<symbol>1->ashol_name;
            }
            | statements statement
            {
               string str = ($<symbol>1)->get_name() + "\n";
               str += ($<symbol>2)->get_name();

               $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

               log_output << "Line " << line_count << ": statements : statements statement" << "\n"  << endl;
               log_output << str << "\n" << endl;

               $<symbol>$->return_type = $<symbol>2->return_type;

               $<symbol>$->code = $<symbol>1->code + $<symbol>2->code;

            }
            ;
       
statement : var_declaration
        {
            string str = ($<symbol>1)->get_name();

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            log_output << "Line " << line_count << ": statement : var_declaration" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->return_type = "void";
        }
        | expression_statement
        {
            string str = ($<symbol>1)->get_name();

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            log_output << "Line " << line_count << ": statement : expression_statement" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->return_type = "void";


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        | compound_statement
        {
          string str = ($<symbol>1)->get_name();

          $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

          log_output << "Line " << line_count << ": statement : compound_statement" << "\n"  << endl;
          log_output << str << "\n" << endl;

          $<symbol>$->return_type = $<symbol>1->return_type;

          $<symbol>$->code = $<symbol>1->code;
          $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        | FOR LPAREN expression_statement expression_statement expression RPAREN statement
        {
            string str = "for(" + ($<symbol>3)->get_name();
            str += ($<symbol>4)->get_name() + ($<symbol>5)->get_name();
            str += ")" + ($<symbol>7)->get_name();

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            log_output << "Line " << line_count << ": statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$->return_type = "void";

            string loop_label = newLabel();
            string new_label = newLabel();
            string new_label_obstacle = newLabel();

            $<symbol>$->code = $<symbol>3->code + "\n";
            $<symbol>$->code += loop_label + ": \n";
            $<symbol>$->code += $<symbol>4->code + "\n";
            $<symbol>$->code += mov("AX",$<symbol>4->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JNE " + new_label + "\n";
            $<symbol>$->code += "JMP " + new_label_obstacle + "\n";
            $<symbol>$->code += new_label + ": \n";
            $<symbol>$->code += $<symbol>7->code + "\n";
            $<symbol>$->code += $<symbol>5->code + "\n";
            $<symbol>$->code += "JMP " + loop_label + "\n";
            $<symbol>$->code += new_label_obstacle + ": \n";
        }
        | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
        {
            string str = "if(" + ($<symbol>3)->get_name();
            str += ")" + ($<symbol>5)->get_name();

            log_output << "Line " << line_count << ": statement : IF LPAREN expression RPAREN statement" << "\n"  << endl; 
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "void";

            string new_label = newLabel();
            string new_label_obstacle = newLabel();

            $<symbol>$->code = $<symbol>3->code;
            $<symbol>$->code += mov("AX",$<symbol>3->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JNE " + new_label + "\n";
            $<symbol>$->code += "JMP " + new_label_obstacle + "\n";
            $<symbol>$->code += new_label + ": \n";
            $<symbol>$->code += $<symbol>5->code + "\n";
            $<symbol>$->code += new_label_obstacle + ": \n";
        }
        | IF LPAREN expression RPAREN statement ELSE statement
        {
            string str = "if(" + ($<symbol>3)->get_name();
            str += ")" + ($<symbol>5)->get_name();
            str += "else" + ($<symbol>7)->get_name();

            log_output << "Line " << line_count << ": statement : IF LPAREN expression RPAREN statement ELSE statement" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "void";

            string new_label_1 = newLabel();
            string new_label_2 = newLabel();
            string new_label_obstacle = newLabel();

            $<symbol>$->code = $<symbol>3->code;
            $<symbol>$->code += mov("AX",$<symbol>3->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JNE " + new_label_1 + "\n";
            $<symbol>$->code += "JMP " + new_label_2 + "\n";
            $<symbol>$->code += new_label_1 + ": \n";
            $<symbol>$->code += $<symbol>5->code + "\n";
            $<symbol>$->code += "JMP " + new_label_obstacle + "\n";
            $<symbol>$->code += new_label_2 + ": \n";
            $<symbol>$->code += $<symbol>7->code + "\n";
            $<symbol>$->code += new_label_obstacle + ": \n";
        }
        | WHILE LPAREN expression RPAREN statement
        {
            string str = "while(" + ($<symbol>3)->get_name();
            str += ")" + ($<symbol>5)->get_name();

            log_output << "Line " << line_count << ": statement : WHILE LPAREN expression RPAREN statement" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "void";

            string loop_label = newLabel();
            string new_label = newLabel();
            string exit_label = newLabel();

            $<symbol>$->code = loop_label + ": \n";
            $<symbol>$->code += $<symbol>3->code;
            $<symbol>$->code += mov("AX",$<symbol>3->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JNE " + new_label + "\n";
            $<symbol>$->code += "JMP " + exit_label + "\n";
            $<symbol>$->code += new_label + ": \n";
            $<symbol>$->code += $<symbol>5->code;
            $<symbol>$->code += "JMP " + loop_label + "\n";
            $<symbol>$->code += exit_label + ": \n"; 
        }
        | PRINTLN LPAREN ID RPAREN SEMICOLON
        {
            string str = "printf(" + ($<symbol>3)->get_name();
            str += ");";

            log_output << "Line " << line_count << ": statement : PRINTLN LPAREN ID RPAREN SEMICOLON" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "void";

            $<symbol>$->code = mov("AX",$<symbol>3->get_name() + Symbol_table.scope_Lookup($<symbol>3->get_name())->get_unique_id());
            $<symbol>$->code += "CALL PRINT \n";
            $<symbol>$->code += "LEA DX, NEWLINE \n";
            $<symbol>$->code += "MOV AH, 9 \n";
            $<symbol>$->code += "INT 21H \n";
        }
        | RETURN expression SEMICOLON
        {
            string str = "return " + ($<symbol>2)->get_name() + ";" ;

            log_output << "Line " << line_count << ": statement : RETURN expression SEMICOLON" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>2->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>$->return_type = "voidCheck";
            } 

            else
            {
                $<symbol>$->return_type = $<symbol>2->return_type;
            }

            string return_temp = newTemp();

            if(current_func_return_label == ""){
                current_func_return_label = newLabel();
            }

            $<symbol>$->code = $<symbol>2->code;
            $<symbol>$->code += mov("AX",$<symbol>2->ashol_name);
            $<symbol>$->code += mov(return_temp,"AX");
            $<symbol>$->code += "JMP " + current_func_return_label + "\n";

            $<symbol>$->ashol_name = return_temp;
        }
        ;
      
expression_statement : SEMICOLON
        {
            string str = ";" ;

            log_output << "Line " << line_count << ": expression_statement : SEMICOLON" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");
        }           
        | expression SEMICOLON
        {
            string str = ($<symbol>1)->get_name() + ";" ;

            log_output << "Line " << line_count << ": expression_statement : expression SEMICOLON" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        } 
        ;
      
variable : ID 
        {
            string str = ($<symbol>1)->get_name();

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            //undeclared variable kina
            SymbolInfo* valid = Symbol_table.Lookup($<symbol>1->get_name());
            if(valid == NULL)
            {
                log_output << "Error at line " << line_count << ": undeclared variable " << $<symbol>1->get_name() <<  "\n" << endl;
                error_output << "Error at line " << line_count << ": undeclared variable " << $<symbol>1->get_name() <<  "\n" << endl;
                error_count++;

                $<symbol>$->return_type = "voidCheck";

            } 

            else
            {
                if(valid->return_type == "void")
                {
                    $<symbol>$->return_type = "float";
                }
                else
                {
                    $<symbol>$->return_type = valid->return_type;
                }

                if(valid->size != -1)            //not a variable
                {
                    if(valid->size >= 0)
                    {
                        log_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is an array"<< "\n" << endl;
                        error_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is an array"<< "\n" << endl;
                        error_count++;
                    }

                    else
                    {
                        log_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a function"<<  "\n" << endl;
                        error_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a function"<<  "\n" << endl;
                        error_count++;
                    }

                }
            }

            log_output << "Line " << line_count << ": variable : ID" << "\n"  << endl;
            log_output << str << "\n" << endl;

            if(ParameterList.size() == 0){
                $<symbol>$->ashol_name = $<symbol>1->get_name() + Symbol_table.scope_Lookup($<symbol>1->get_name())->get_unique_id();
            }

            else{

                bool defined_in_parameter = false;
                for(int i = 0; i < ParameterList.size(); i++){
                    if($<symbol>1->get_name() == ParameterList[i].parameter_name){
                        $<symbol>$->ashol_name = valid->ashol_name;
                        defined_in_parameter = true;
                    }
                }

                if(defined_in_parameter == false){
                    $<symbol>$->ashol_name = $<symbol>1->get_name() + Symbol_table.scope_Lookup($<symbol>1->get_name())->get_unique_id();
                }
            }
        }
        
        | ID LTHIRD expression RTHIRD
        {
            string str = ($<symbol>1)->get_name() + "[";
            str += ($<symbol>3)->get_name() + "]";

            log_output << "Line " << line_count << ": variable : ID LTHIRD expression RTHIRD" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            SymbolInfo* valid = Symbol_table.Lookup($<symbol>1->get_name());
            if(valid == NULL)
            {
                log_output << "Error at line " << line_count << ": undeclared variable" << $<symbol>1->get_name() <<  "\n" << endl;
                error_output << "Error at line " << line_count << ": undeclared variable" << $<symbol>1->get_name() <<  "\n" << endl;
                error_count++;

                $<symbol>$->return_type = "float";
            }

            else
            {
                if(valid->return_type == "void")
                {
                    $<symbol>$->return_type = "float";       //???????????
                }
                else
                {
                    $<symbol>$->return_type = valid->return_type;
                }

                if(valid->size < 0)            //not an array
                {
                    if(valid->size == -1)
                    {
                        log_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a variable"<<  "\n" << endl;
                        error_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a variable"<<  "\n" << endl;
                        error_count++;
                    }

                    else
                    {
                        log_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a function"<<  "\n" << endl;
                        error_output << "Error at line " << line_count << ": Type mismatch, " << $<symbol>1->get_name() << " is a function"<<  "\n" << endl;
                        error_count++;
                    }

                }
            }

            string returnType = $<symbol>3->return_type;

            if( returnType != "int")      //non integer array index
            {
                log_output << "Error at line " << line_count << ": Expression inside third brackets not an integer" <<  "\n" << endl;
                error_output << "Error at line " << line_count << ": Expression inside third brackets not an integer" <<  "\n" << endl;
                error_count++;
            } 

            $<symbol>$->ashol_name = $<symbol>1->get_name() + Symbol_table.GetCurrentScopeTable()->get_unique_id();
            $<symbol>$->code = $<symbol>3->code;
        } 
        ;
     
expression : logic_expression   
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": expression : logic expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        | variable ASSIGNOP logic_expression
        {
           string str = ($<symbol>1)->get_name() + "=" + ($<symbol>3)->get_name();
            
           log_output << "Line " << line_count << ": expression : variable ASSIGNOP logic_expression" << "\n"  << endl;
           log_output << str << "\n" << endl;

           $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

           if($<symbol>3->return_type == "void")
           {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>3->return_type = "voidCheck";
           }

           if($<symbol>1->return_type == "voidCheck" || $<symbol>3->return_type == "voidCheck")
           {
                $<symbol>$->return_type = "voidCheck";
           }

           else
           {
                string variable_return_type = $<symbol>1->return_type;
                string logic_return_type = $<symbol>3->return_type;

                if(variable_return_type == "float" && logic_return_type == "int")
                {
                     $<symbol>$->return_type = "float"; 
                }

                else if(variable_return_type != logic_return_type)
                {
                     log_output << "Error at line " << line_count << ": Type Mismatch" << "\n" << endl;
                     error_output << "Error at line " << line_count << ": Type Mismatch" << "\n" << endl;
                     error_count++;
          
                }

               $<symbol>$->return_type = $<symbol>1->return_type;  
           }

           $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;
           $<symbol>$->code += comment_writing(str);
           $<symbol>$->code += mov("AX",$<symbol>3->ashol_name);
           $<symbol>$->code += mov($<symbol>1->ashol_name, "AX");

           $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }    
        ;
            
logic_expression : rel_expression
        {
           string str = ($<symbol>1)->get_name(); 

           log_output << "Line " << line_count << ": logic_expression : rel_expression" << "\n"  << endl;
           log_output << str << "\n" << endl;

           $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

           $<symbol>$->return_type = $<symbol>1->return_type; 


           $<symbol>$->code = $<symbol>1->code;
           $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }    
        | rel_expression LOGICOP rel_expression
        {
           string str = ($<symbol>1)->get_name() + ($<symbol>2)->get_name() + ($<symbol>3)->get_name();
            
           log_output << "Line " << line_count << ": logic_expression : rel_expression LOGICOP rel_expression" << "\n"  << endl;
           log_output << str << "\n" << endl;

           $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

           if($<symbol>1->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;
            }

            if($<symbol>3->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;
            }

            $<symbol>$->return_type = "int";

            $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;
            $<symbol>$->code += comment_writing(str);

            string new_label_1 = newLabel();
            string new_label_2 = newLabel();
            string exit_label = newLabel();
            string temp = newTemp();

            $<symbol>$->code += mov("AX", $<symbol>1->ashol_name);
            $<symbol>$->code += mov("BX", $<symbol>3->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JNE " + new_label_1 + "\n";

            if($<symbol>2->get_name() == "&&"){
                $<symbol>$->code += mov("AX", "0");
                $<symbol>$->code += "JMP " + exit_label + "\n";
                $<symbol>$->code += new_label_1 + ": \n";
                $<symbol>$->code += "CMP BX, 0 \n";
                $<symbol>$->code += "JNE " + new_label_2 + "\n";
                $<symbol>$->code += mov("AX", "0");
                $<symbol>$->code += "JMP " + exit_label + "\n";
            }

            else{
                $<symbol>$->code += "CMP BX, 0 \n";
                $<symbol>$->code += "JNE " + new_label_2 + "\n";
                $<symbol>$->code += mov("AX", "0");
                $<symbol>$->code += "JMP " + exit_label + "\n";
                $<symbol>$->code += new_label_1 + ": \n";
                $<symbol>$->code += mov("AX", "1");
                $<symbol>$->code += "JMP " + exit_label + "\n";
            }

            $<symbol>$->code += new_label_2 + ": \n";
            $<symbol>$->code += mov("AX", "1");
            $<symbol>$->code += exit_label + ": \n";
            $<symbol>$->code += mov(temp,"AX");

            $<symbol>$->ashol_name = temp;
        }  
        ;
            
rel_expression  : simple_expression
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": rel_expression : simple_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        } 
        | simple_expression RELOP simple_expression
        {
            string str = ($<symbol>1)->get_name() + ($<symbol>2)->get_name() + ($<symbol>3)->get_name();

            log_output << "Line " << line_count << ": rel_expression : simple_expression RELOP simple_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>1->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;
            }

            if($<symbol>3->return_type == "void")
            {               
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;
            }

            $<symbol>$->return_type = "int";


            $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;
            $<symbol>$->code += comment_writing(str);
            $<symbol>$->code += mov("AX",$<symbol>1->ashol_name);
            $<symbol>$->code += "CMP AX, " + $<symbol>3->ashol_name + "\n";

            string new_label = newLabel();
            string new_label_obstacle = newLabel();
            string temp = newTemp();
            if($<symbol>2->get_name() == "<"){
                $<symbol>$->code += "JL " + new_label + "\n";
            }
            else if($<symbol>2->get_name() == "<="){
                $<symbol>$->code += "JLE " + new_label + "\n";
            }
            else if($<symbol>2->get_name() == ">"){
                $<symbol>$->code += "JG " + new_label + "\n";
            }
            else if($<symbol>2->get_name() == ">="){
                $<symbol>$->code += "JGE " + new_label + "\n";
            }
            else if($<symbol>2->get_name() == "=="){
                $<symbol>$->code += "JE " + new_label + "\n";
            }
            else{
                $<symbol>$->code += "JNE " + new_label + "\n";
            }

            $<symbol>$->code += mov("AX","0");
            $<symbol>$->code += "JMP " + new_label_obstacle + "\n";
            $<symbol>$->code += new_label + ": \n";
            $<symbol>$->code += mov("AX","1");
            $<symbol>$->code += new_label_obstacle + ": \n";
            $<symbol>$->code += mov(temp,"AX");

            $<symbol>$->ashol_name = temp;
        }   
        ;
                
simple_expression : term 
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": simple_expression : term" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        | simple_expression ADDOP term 
        {
            string str = ($<symbol>1)->get_name() + ($<symbol>2)->get_name() + ($<symbol>3)->get_name();

            log_output << "Line " << line_count << ": simple_expression : simple_expression ADDOP term" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>1->return_type == "void")
            {

                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>1->return_type = "voidCheck";
            }

            if($<symbol>3->return_type == "void")
            {
                
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>3->return_type = "voidCheck";
            }

            if($<symbol>1->return_type == "voidCheck" || $<symbol>3->return_type == "voidCheck")
            {
                $<symbol>$->return_type = "voidCheck";
            }

            else
            {
                if($<symbol>1->return_type == "float" || $<symbol>3->return_type == "float")
                {
                    $<symbol>$->return_type = "float";
                }
            else
                {
                    $<symbol>$->return_type = "int";
                }
            }

          $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;  
          $<symbol>$->code += comment_writing(str);

          string temp = newTemp();
          //for plus operator 
          if($<symbol>2->get_name() == "+"){
            $<symbol>$->code += mov("AX",$<symbol>3->ashol_name);
            $<symbol>$->code += "ADD AX, " + $<symbol>1->ashol_name + "\n";
            $<symbol>$->code += mov(temp,"AX");
          }
          //for minus operator
          else{
            $<symbol>$->code += mov("AX",$<symbol>1->ashol_name);
            $<symbol>$->code += "SUB AX, " + $<symbol>3->ashol_name + "\n";
            $<symbol>$->code += mov(temp,"AX");
          }

          $<symbol>$->ashol_name = temp;
        }
        ;
                    
term :  unary_expression
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": term : unary_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        |  term MULOP unary_expression
        {
            string str = ($<symbol>1)->get_name() + ($<symbol>2)->get_name() + ($<symbol>3)->get_name();

            log_output << "Line " << line_count << ": term : term MULOP unary_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>1->return_type == "void")
            {

                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>1->return_type = "voidCheck";
            }

            if($<symbol>3->return_type == "void")
            {
                
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>3->return_type = "voidCheck";
            }

            if($<symbol>1->return_type == "voidCheck" || $<symbol>3->return_type == "voidCheck")
            {
                $<symbol>$->return_type = "voidCheck";
            }

            else{

                string mulop = $<symbol>2->get_name();

            if(mulop == "%")     // inside modulus operator
            {
                if($<symbol>1->return_type != "int" || $<symbol>3->return_type != "int")
                {
                    log_output << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << "\n" << endl;
                    error_output << "Error at line " << line_count << ": Non-Integer operand on modulus operator" << "\n" << endl;
                    error_count++; 
                }

                if($<symbol>3->get_name() == "0")
                {
                    log_output << "Error at line " << line_count << ": Modulus by Zero" << "\n" << endl;
                    error_output << "Error at line " << line_count << ": Modulus by Zero" << "\n" << endl;
                    error_count++;
                }

                $<symbol>$->return_type = "int";
            }

            else if(mulop == "/")
            {
                if($<symbol>3->get_name() == "0")
                {
                    log_output << "Error at line " << line_count << ": divided by Zero" << "\n" << endl;
                    error_output << "Error at line " << line_count << ": divided by Zero" << "\n" << endl;
                    error_count++;
                }

                if($<symbol>1->return_type == "float" || $<symbol>3->return_type == "float")
                {
                    $<symbol>$->return_type = "float";
                }
                else
                {
                    $<symbol>$->return_type = "int";
                }
            }

            else
            {
                if($<symbol>1->return_type == "float" || $<symbol>3->return_type == "float")
                {
                    $<symbol>$->return_type = "float";
                }
                else
                {
                    $<symbol>$->return_type = "int";
                }
            }
        }


            $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;
            string temp = newTemp();

            $<symbol>$->code += comment_writing(str);
            if($<symbol>2->get_name() == "*"){
                $<symbol>$->code += mov("AX", $<symbol>1->ashol_name);
                $<symbol>$->code += mov("BX", $<symbol>3->ashol_name);
                $<symbol>$->code += "IMUL BX \n";
                $<symbol>$->code += mov(temp,"AX");
                $<symbol>$->ashol_name = temp;
            }

            else {
                $<symbol>$->code += "XOR DX, DX \n";
                $<symbol>$->code += mov("AX", $<symbol>1->ashol_name);
                $<symbol>$->code += mov("BX", $<symbol>3->ashol_name);
                $<symbol>$->code += "IDIV BX \n";

                if($<symbol>2->get_name() == "/"){
                    $<symbol>$->code += mov(temp,"AX");
                    $<symbol>$->ashol_name = temp;
                }

                else{
                   $<symbol>$->code += mov(temp,"DX");
                   $<symbol>$->ashol_name = temp;
                }

        }
    }    
    ;

unary_expression : ADDOP unary_expression 
        {
            string str = ($<symbol>1)->get_name() + ($<symbol>2)->get_name();

            log_output << "Line " << line_count << ": unary_expression : ADDOP unary_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>2->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>2->return_type = "voidCheck";
            }

            $<symbol>$->return_type = $<symbol>2->return_type;

            
            $<symbol>$->code = $<symbol>2->code;                            
            if($<symbol>1->get_name() == "-"){
                $<symbol>$->code +=  "NEG " + $<symbol>2->ashol_name + "\n";       
            }
            $<symbol>$->ashol_name = $<symbol>2->ashol_name;                   
        } 
        | NOT unary_expression 
        {
            string str = "!" + ($<symbol>2)->get_name();

            log_output << "Line " << line_count << ": unary_expression : NOT unary_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>2->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

            }

            $<symbol>$->return_type = "int";

            string new_label = newLabel();
            string new_label_obstacle = newLabel();

            $<symbol>$->code = $<symbol>2->code;
            $<symbol>$->code += mov("AX", $<symbol>2->ashol_name);
            $<symbol>$->code += "CMP AX, 0 \n";
            $<symbol>$->code += "JE " + new_label + "\n";
            $<symbol>$->code += mov("AX","0");
            $<symbol>$->code += "JMP " + new_label_obstacle + "\n";
            $<symbol>$->code += new_label + ": \n";
            $<symbol>$->code += mov("AX","1");
            $<symbol>$->code += new_label_obstacle + ": \n";
            $<symbol>$->code += mov($<symbol>2->ashol_name,"AX");

            $<symbol>$->ashol_name = $<symbol>2->ashol_name;
        }
        | factor 
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": unary_expression : factor" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        ;
    
factor  : variable 
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": factor : variable" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = ($<symbol>1)->return_type;


            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
            $<symbol>$->code = $<symbol>1->code;

        }
        | ID LPAREN argument_list RPAREN
        {
            string str = ($<symbol>1)->get_name() + "(";
            str += ($<symbol>3)->get_name() + ")";

            log_output << "Line " << line_count << ": factor : ID LPAREN argument_list RPAREN" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            SymbolInfo* func = Symbol_table.Lookup($<symbol>1->get_name());
            if(func == NULL)
            {
                log_output << "Error at line " << line_count << ": undeclared function " << $<symbol>1->get_name() <<  "\n" << endl;
                error_output << "Error at line " << line_count << ": undeclared fuction " << $<symbol>1->get_name() <<  "\n" << endl;
                error_count++;
            }

            else
            {
                if(func->size != -2 && func->size != -3)
                {
                    error_output << func->size << endl;
                    log_output << "Error at line " << line_count << ": " << $<symbol>1->get_name() << " is not a function" <<  "\n" << endl;
                    error_output << "Error at line " << line_count << ": "<< $<symbol>1->get_name() << " is not a function" <<  "\n" << endl;
                    error_count++;
                }

                else if(func->size == -2)
                {
                    log_output << "Error at line " << line_count << ": " << $<symbol>1->get_name() << " function not defined" <<  "\n" << endl;
                    error_output << "Error at line " << line_count << ": "<< $<symbol>1->get_name() << " function not defined" <<  "\n" << endl;
                    error_count++;
                }

                else
                {
                    if(arg_list.size() != func->parameter_list.size())
                    {
                        log_output << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $<symbol>1->get_name() <<  "\n" << endl;
                        error_output << "Error at line " << line_count << ": Total number of arguments mismatch in function " << $<symbol>1->get_name() <<  "\n" << endl;
                        error_count++;
                    }

                    else
                    {
                        for(int i = 0; i < arg_list.size(); i++)
                        {
                           if(arg_list[i].parameter_type != func->parameter_list[i].parameter_type)
                                {
                                    log_output << "Error at line no " << line_count << ": " << i+1 << "th argument mismatch in function " << $<symbol>1->get_name() << "\n" << endl;
                                    error_output << "Error at line no " << line_count << ": " << i+1 << "th argument mismatch in function " << $<symbol>1->get_name() << "\n" << endl;
                                    error_count++; 
                                }
                        }
                    }
                }    
            }

            $<symbol>$->code = $<symbol>3->code;
            string temp = newTemp();

            for(int i = 0; i < argument_ashol_name.size(); i++){
                $<symbol>$->code += "PUSH " + argument_ashol_name[i] + "\n";
            }

            $<symbol>$->code += "CALL " + $<symbol>1->get_name() + "\n";
            $<symbol>$->code += mov(temp, "AX");

            $<symbol>$->ashol_name = temp;
        }
        | LPAREN expression RPAREN
        {
            string str = "(" + ($<symbol>2)->get_name() + ")";

            log_output << "Line " << line_count << ": factor : LPAREN expression RPAREN" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>2->return_type == "void")
            {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>2->return_type = "voidCheck";
            }

            $<symbol>$->return_type = $<symbol>2->return_type;


            $<symbol>$->code = $<symbol>2->code;
            $<symbol>$->ashol_name = $<symbol>2->ashol_name;
        }
        | CONST_INT 
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": factor : CONST_INT" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "int";


            $<symbol>$->ashol_name = $<symbol>1->get_name();
        }
        | CONST_FLOAT
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": factor : CONST_FLOAT" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = "float";


            $<symbol>$->ashol_name = $<symbol>1->get_name();
        }
        | variable INCOP 
        {
            string str = ($<symbol>1)->get_name() + "++";

            log_output << "Line " << line_count << ": factor : variable INCOP" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;

            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->code += "INC " + ($<symbol>1)->ashol_name + "\n";

            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        | variable DECOP
        {
            string str = ($<symbol>1)->get_name() + "--";

            log_output << "Line " << line_count << ": factor : variable DECOP" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->return_type = $<symbol>1->return_type;


            $<symbol>$->code = $<symbol>1->code;
            $<symbol>$->code += "DEC " + ($<symbol>1)->ashol_name + "\n";

            $<symbol>$->ashol_name = $<symbol>1->ashol_name;
        }
        ;
    
argument_list : arguments
        {
            string str = ($<symbol>1)->get_name();

            log_output << "Line " << line_count << ": argument_list : arguments" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            $<symbol>$->code = $<symbol>1->code;
        }
        |
        {
            $<symbol>$ = new SymbolInfo("","NON_TERMINAL");

            log_output << "Line " << line_count << ": argument_list : empty rule" << "\n"  << endl;
            log_output << "" << "\n" << endl;
        }
        ;
    
arguments : arguments COMMA logic_expression
        {
            string str = ($<symbol>1)->get_name() + "," + ($<symbol>3)->get_name();

            log_output << "Line " << line_count << ": arguments : arguments COMMA logic_expression" << "\n"  << endl;
            log_output << str << "\n" << endl;

            $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

            if($<symbol>3->return_type == "void")
           {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>3->return_type = "voidCheck"; 
           }

           else
           {
                single_parameter.parameter_name = "";
                single_parameter.parameter_type = $<symbol>3->return_type;

                arg_list.push_back(single_parameter);
           }

           $<symbol>$->code = $<symbol>1->code + $<symbol>3->code;
           argument_ashol_name.push_back($<symbol>3->ashol_name);
        }
        | logic_expression
        {
           string str = ($<symbol>1)->get_name();

           log_output << "Line " << line_count << ": arguments : logic_expression" << "\n"  << endl;
           log_output << str << "\n" << endl;

           $<symbol>$ = new SymbolInfo(str, "NON_TERMINAL");

           if($<symbol>1->return_type == "void")
           {
                log_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_output << "Error at line " << line_count << ": Void function used in expression" << "\n" << endl;
                error_count++;

                $<symbol>1->return_type = "voidCheck"; 
           }

           else
           {
                single_parameter.parameter_name = "";
                single_parameter.parameter_type = $<symbol>1->return_type;

                arg_list.push_back(single_parameter);
           }

           $<symbol>$->code = $<symbol>1->code;
           argument_ashol_name.push_back($<symbol>1->ashol_name);
        }
        ;
 
        

%%
int main(int argc,char *argv[])
{

    if((fp=fopen(argv[1],"r"))==NULL)
    {
        printf("Cannot Open Input File.\n");
        exit(1);
    }

    log_output.open("log.txt");
    error_output.open("error.txt");
    code_output.open("code.asm");
    //optimised_code_output.open("optimized_code.asm");

    yyin=fp;
    yyparse();

    
    return 0;
}

