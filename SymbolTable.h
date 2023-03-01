#ifndef SCOPETABLE_H
    #define SCOPETABLE_H
    #include "ScopeTable.h"
#endif // SCOPETABLE_H

class SymbolTable
{
private:
    ScopeTable* CurrentScopeTable;
    int BucketSize;
public:
    SymbolTable(int bucket_size)
    {
        this->BucketSize = bucket_size;
        this->CurrentScopeTable = new ScopeTable(bucket_size,nullptr);
    }

    void SetCurrentScopeTable(ScopeTable* current_scope_table)
    {
        this->CurrentScopeTable = current_scope_table;
    }

    ScopeTable* GetCurrentScopeTable()
    {
        return this->CurrentScopeTable;
    }

    void SetBucketSize(int bucket_size)
    {
        this->BucketSize = bucket_size;
    }

    int GetBucketSize()
    {
        return this->BucketSize;
    }

    void EnterScope()
    {
        ScopeTable* NewScopeTable = new ScopeTable(this->BucketSize,this->CurrentScopeTable);
        this->CurrentScopeTable->set_number_of_child(this->CurrentScopeTable->get_number_of_child() + 1);
        this->CurrentScopeTable = NewScopeTable;
        //cout << "New ScopeTable with id " << CurrentScopeTable->get_unique_id() << " created" << endl;
    }

    void ExitScope()
    {
        //cout << "ScopeTable with id " << CurrentScopeTable->get_unique_id() << " removed" << endl;
        ScopeTable* parentScope = CurrentScopeTable->get_parentScope();
        delete CurrentScopeTable;
        this->CurrentScopeTable = parentScope;
    }

    bool Insert(SymbolInfo* symbol)
    {
        return this->CurrentScopeTable->Insert(symbol);
    }

    bool Remove(string name)
    {
        return this->CurrentScopeTable->Delete(name);
    }

    SymbolInfo* Lookup(string name)
    {
        ScopeTable* current;
        current = CurrentScopeTable;
        while(current != nullptr)
        {
            if(current->Look_up(name) != nullptr)
            {
                //cout << "Found in ScopeTable# " << current->get_unique_id() << " at position " << to_string(current->hash_function(name)) << ", " << current->get_position(name) << endl;
                return current->Look_up(name);
            }
            current = current->get_parentScope();
        }
        //cout << "Not found" << endl;
        return nullptr;
    }

    ScopeTable* scope_Lookup(string name)
    {
        ScopeTable* current;
        current = CurrentScopeTable;
        while(current != nullptr)
        {
            if(current->Look_up(name) != nullptr)
            {
                //cout << "Found in ScopeTable# " << current->get_unique_id() << " at position " << to_string(current->hash_function(name)) << ", " << current->get_position(name) << endl;
                return current;
            }
            current = current->get_parentScope();
        }
        //cout << "Not found" << endl;
        return nullptr;
    }

    void PrintCurrentScopeTable(ofstream& logout)
    {
        this->CurrentScopeTable->print(logout);
    }

    void PrintAllScopeTable(ofstream& logout)
    {
        ScopeTable* current;
        current = this->CurrentScopeTable;

        while(current != nullptr)
        {
            current->print(logout);
            current = current->get_parentScope();
        }
    }

    ~SymbolTable()
    {
        while(CurrentScopeTable != nullptr)
        {
            ScopeTable* PreviousScopeTable = CurrentScopeTable->get_parentScope();
            delete CurrentScopeTable;
            CurrentScopeTable = PreviousScopeTable;
        }
    }
};




