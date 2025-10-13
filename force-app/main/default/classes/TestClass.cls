public class TestClass {
    public static void example(){
        System.debug('Hello world');
    }
	//3 variables private, 1 string, 1 decimal, 1 integer, 2 constructors- 1 default, 1 parameterised
	private String a;
    private Decimal b;
    private Integer x;
    TestClass(){
        this.a = '10';
        this.x = 1;
    }
    TestClass(String a, Integer x){ //parameterised constructor
        this.a = a;
        this.x = x;
    }
    TestClass(Integer z, String b){ //parameterised constructor
        this.a = b;
        this.x = z;
    }
    //TestClass obj = new TestClass(10, "Aman");
    //default constructor is loaded on its own whenever we declare a class, and if we create a constructor, default one is not created
    
}