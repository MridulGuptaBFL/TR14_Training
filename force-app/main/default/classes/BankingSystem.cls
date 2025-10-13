public class BankingSystem {
    public interface FinancialOperation {    //  Interface defining a financial operation
        void evaluate();
    }
    public class SavingsAccount implements FinancialOperation {    //  Savings account implementing FinancialOperation
        public Decimal balance;
        public Decimal interestRate;
        public SavingsAccount(Decimal balance, Decimal interestRate) {
            this.balance = balance;
            this.interestRate = interestRate;
        }
        public void evaluate() {
            Decimal interest = balance * interestRate / 100;
            balance += interest;
            System.debug('Savings Account Updated Balance: ₹' + balance.setScale(2));
        }
    }
    public class LoanApplication implements FinancialOperation {    //  Loan application implementing FinancialOperation
        public Decimal principal;
        public Integer termMonths;
        public Decimal interestRate;
        public LoanApplication(Decimal principal, Integer termMonths, Decimal interestRate) {
            this.principal = principal;
            this.termMonths = termMonths;
            this.interestRate = interestRate;
        }
        public void evaluate() {
            Double monthlyRate = Double.valueOf(interestRate) / 12 / 100;
            Double denominator = 1 - Math.pow(1 + monthlyRate, -termMonths);
            Double monthlyPayment = (Double.valueOf(principal) * monthlyRate) / denominator;
            System.debug('Monthly Loan Payment: ₹' + Decimal.valueOf(monthlyPayment).setScale(2));
        }
    }
    public static void runDemo() {
        FinancialOperation savings = new SavingsAccount(10000, 4.5);
        FinancialOperation loan = new LoanApplication(200000, 24, 8.5);

        savings.evaluate(); // Applies interest
        loan.evaluate();    // Calculates EMI
    }
}