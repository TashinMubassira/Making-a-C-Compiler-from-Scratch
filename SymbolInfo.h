struct parameter{
        string parameter_type;
        string parameter_name;
    };


class SymbolInfo
{
private:
    string name;
    string Type;
    SymbolInfo *next_symbol;

public:
    int size;               // -1 means variable, positive means array,function declaration = -2,function definition = -3
    string return_type;    //int,void,float,function er return type
    string code;
    string ashol_name;

    vector<parameter> parameter_list;
    
    SymbolInfo() {
        this->next_symbol = nullptr;
        this->name = "";
        this->Type = "";
        this->size = -1;
        this->return_type = "";         
    }
    SymbolInfo(string name,string type) {
        this->next_symbol = nullptr;
        this->name = name;
        this->Type = type;
        this->size = -1;
        this->return_type = "";
    }
    void set_name(string name) {
        this->name = name;
    }
    void set_type(string type) {
        this->Type = type;
    }
    void set_next_symbol(SymbolInfo *next_symbol) {
        this->next_symbol = next_symbol;
    }

    string get_name() {
        return this->name;
    }
    string get_type() {
        return this->Type;
    }
    SymbolInfo* get_next_symbol() {
        return this->next_symbol;
    }

    ~SymbolInfo() {

    }
};



