#ifndef SYMBOLINFO_H
    #define SYMBOLINFO_H
    #include "SymbolInfo.h"
#endif // SYMBOLINFO_H

class ScopeTable
{
private:
    vector<SymbolInfo*> hash_table;
    ScopeTable* parentScope;
    int number_of_child;
    string unique_id;
    int number_of_buckets;

public:
    
    ScopeTable(int no_of_buckets,ScopeTable *parent) {
        this->number_of_buckets = no_of_buckets;
        hash_table.resize(this->number_of_buckets);
        for(int i = 0; i < hash_table.size(); i++)
        {
            hash_table[i] = nullptr;
        }
        this->number_of_child = 0;
        if(parent == nullptr)
        {
            this->parentScope = nullptr;
            this->unique_id = "1";
        }
        else
        {
            this->parentScope = parent;
            this->unique_id = parentScope->get_unique_id() + "_" + to_string(parentScope->get_number_of_child() + 1);
        }
    }
    

    void set_hash_table(vector<SymbolInfo*> hash_table) {
        this->hash_table = hash_table;
    }

    int hash_function(string name) {
        int sum_of_ascii = 0;
        for(int i = 0; i < name.size(); i++)
        {
            sum_of_ascii += name[i];
        }
        int bucket_no = sum_of_ascii % (this->number_of_buckets);

        return bucket_no;
    }

    vector<SymbolInfo*> get_hash_table()
    {
        return this->hash_table;
    }

    void set_parentScope(ScopeTable* parentScope)
    {
        this->parentScope = parentScope;
    }

    ScopeTable* get_parentScope()
    {
        return this->parentScope;
    }

    void set_unique_id(string unique_id)
    {
        this->unique_id = unique_id;
    }

    string get_unique_id()
    {
        return this->unique_id;
    }

    void set_number_of_buckets(int no_of_buckets)
    {
        this->number_of_buckets = no_of_buckets;
    }

    int get_number_of_buckets()
    {
        return this->number_of_buckets;
    }

    void set_number_of_child(int no_of_child)
    {
        this->number_of_child = no_of_child;
    }

    int get_number_of_child()
    {
        return this->number_of_child;
    }

    bool Insert(SymbolInfo* symbol_info)
    {
        if(Look_up(symbol_info->get_name()) == nullptr)
        {
            int position = 0;
            int bucket_no = hash_function(symbol_info->get_name());
            if(hash_table[bucket_no] != nullptr)
            {
                SymbolInfo* current_symbol = hash_table[bucket_no];
                while(current_symbol->get_next_symbol() != nullptr)
                {
                   current_symbol = current_symbol->get_next_symbol();
                   position++;
                }
                current_symbol->set_next_symbol(symbol_info);
                position = position + 1;
            }
            else
            {
                hash_table[bucket_no] = symbol_info;
            }
            //cout << "I " << symbol_info->get_name() << " " << symbol_info->get_type() << endl;
            //cout << endl;
            //cout << "Inserted in ScopeTable# " + get_unique_id() << " at position " << to_string(bucket_no) << ", " << to_string(position) << endl;
            return true;
        }
        else
        {
            //cout << "<" << symbol_info->get_name() << "," << symbol_info->get_type() << ">" << " already exists in current ScopeTable" << endl;
            return false;
        }
    }

    SymbolInfo* Look_up(string name)
    {
        int bucket_no = hash_function(name);
        SymbolInfo* current_symbol = hash_table[bucket_no];

        while(current_symbol != nullptr)
        {
            if(current_symbol->get_name() == name)
            {
                return current_symbol;
            }
            current_symbol = current_symbol->get_next_symbol();
        }

        return nullptr;
    }

    bool Delete(string name)
    {
        if(Look_up(name) == nullptr)
        {
            //cout << "Not found" << endl;
            return false;
        }

        int bucket_no = hash_function(name);
        SymbolInfo* current_symbol = hash_table[bucket_no];
        SymbolInfo* parent_symbol = nullptr;

        //cout << "Deleted entry " << to_string(bucket_no) << ", " << get_position(name) << " from current ScopeTable" << endl;
        if(current_symbol->get_name() == name)
        {
            delete hash_table[bucket_no];
            hash_table[bucket_no] = current_symbol->get_next_symbol();
        }
        else
        {
            while(current_symbol->get_name() != name)
            {
                parent_symbol = current_symbol;
                current_symbol = current_symbol->get_next_symbol();
            }

            SymbolInfo* nextSymbol = current_symbol->get_next_symbol();
            parent_symbol->set_next_symbol(nextSymbol);
            delete current_symbol;
        }
        return true;
    }
    void print(ofstream& logout)
    {
        logout << "ScopeTable # " + get_unique_id();
        logout << endl;

        for(int i = 0; i < hash_table.size(); i++)
        {
        if( hash_table[i] == nullptr )
        {
            continue;
        }
            logout << i << " -->";
            SymbolInfo* current_symbol = hash_table[i];
            while(current_symbol != nullptr)
            {
                logout << "  < " << current_symbol->get_name() << " : " << current_symbol->get_type() << ">";
                current_symbol = current_symbol->get_next_symbol();
            }
            logout << endl;
        }
    }

    string get_position(string name)
    {
        int bucket_no = hash_function(name);
        SymbolInfo* current_symbol = hash_table[bucket_no];
        int position = 0;

        while(current_symbol != nullptr)
        {
            if(current_symbol->get_name() == name)
            {
                return to_string(position);
            }
            current_symbol = current_symbol->get_next_symbol();
            position++;
        }
        return "";
    }

    ~ScopeTable()
    {

        for(int i = 0; i < hash_table.size(); i++)
        {
            SymbolInfo* current_symbol = hash_table[i];
            while(current_symbol != nullptr)
            {
                SymbolInfo* NextSymbol = current_symbol->get_next_symbol();
                delete current_symbol;
                current_symbol = NextSymbol;
            }
        }
    }


};


