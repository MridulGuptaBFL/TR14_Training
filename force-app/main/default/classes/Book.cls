public class Book {
    private String title;
    private String author;
    private Decimal price;
    
    public Book(String title, String author, Decimal price) {
        this.title = title;
        this.author = author;
        this.price = price;
    }
    // Getters and Setters
    public String getTitle() { //title
        return title;
    } public void setTitle(String title) {
        this.title = title;
    }
    public String getAuthor() {//author
        return author;
    } public void setAuthor(String author) {
        this.author = author;
    }
    public Decimal getPrice() {//price
        return price;
    } public void setPrice(Decimal price) {
        this.price = price;
    }
    // Method to print book details
    public void printDetails() {
        System.debug('Title: ' + this.getTitle() + ', Author: ' + author + ', Price: ₹' + price);
    }
    public static void runTest() {
        Book book1 = new Book('The Alchemist', 'Paulo Coelho', 299.99);// Creating 3 instances
        Book book2 = new Book('Atomic Habits', 'James Clear', 499.50);
        Book book3 = new Book('Sapiens', 'Yuval Noah Harari', 599.00);
        book1.printDetails();        // Call fnc to Print
        book2.printDetails();
        book3.printDetails();
    } }