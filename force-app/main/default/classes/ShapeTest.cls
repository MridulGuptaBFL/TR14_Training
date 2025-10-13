public class ShapeTest {	//apex class file
    public abstract class Shape {    // Abstract base inner class
        public abstract Decimal calculateArea(); //to be overridden
    } public class Rectangle extends Shape {    //  Rectangle class extending Shape
        public Decimal length;
        public Decimal width;

        public Rectangle(Decimal length, Decimal width) { 	//constructor
            this.length = length;
            this.width = width;
        }
        public override Decimal calculateArea() {	// overriding
            Decimal area = length * width;
            System.debug('Rectangle Area: ' + area);
            return area;
        }
    }
    public class Triangle extends Shape {	    // Triangle class extending Shape
        public Decimal baseLength;
        public Decimal height;
        public Triangle(Decimal baseLength, Decimal height) { 	//constructor
            this.baseLength = baseLength;
            this.height = height;
        }
        public override Decimal calculateArea() {
            Decimal area = 0.5 * baseLength * height;
            System.debug('Triangle Area: ' + area);
            return area;
        }
    }
    public static void runTest() {	//test
        Shape rect = new Rectangle(10, 5);
        rect.calculateArea(); // Output: Rectangle Area: 50

        Shape tri = new Triangle(8, 4);
        tri.calculateArea(); // Output: Triangle Area: 16
    }
}