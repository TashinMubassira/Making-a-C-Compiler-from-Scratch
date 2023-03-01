int factorial(int x){
	if(x == 0 || x == 1 ){
		return 1;	
	}
	
	return x * factorial(x-1);
}


int main(){
    int a;
    a = 3;
    int b;
    b = factorial(a);
    println(b);
}
