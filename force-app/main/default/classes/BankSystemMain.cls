public class BankSystemMain {
    //  Base class for bank accounts
    public virtual class BankAccountBase {
        public String accountNumber;
        public Decimal balance;
        public BankAccountBase(String accountNumber, Decimal initialBalance) {
            this.accountNumber = accountNumber;
            this.balance = initialBalance;
        }
        public virtual void deposit(Decimal amount) {
            balance += amount;
        }
        public virtual Boolean withdraw(Decimal amount) {
            if (balance >= amount) {
                balance -= amount;
                return true;
            }
            return false;
        }
        public Decimal getBalance() {
            return balance;
        }
    }
    //  Savings account with interest
    public class SavingsBankAccount extends BankAccountBase {
        public Decimal interestRate;
        public SavingsBankAccount(String accountNumber, Decimal initialBalance, Decimal interestRate) {
            super(accountNumber, initialBalance);
            this.interestRate = interestRate;
        }
        public void applyInterest() {
            balance += balance * interestRate / 100;
        }
    }
    //  Current account with overdraft
    public class CurrentBankAccount extends BankAccountBase {
        public Decimal overdraftLimit;
        public CurrentBankAccount(String accountNumber, Decimal initialBalance, Decimal overdraftLimit) {
            super(accountNumber, initialBalance);
            this.overdraftLimit = overdraftLimit;
        }
        public override Boolean withdraw(Decimal amount) {
            if (balance + overdraftLimit >= amount) {
                balance -= amount;
                return true;
            }
            return false;
        }
    }
    //  Customer profile
    public class BankCustomerProfile {
        public String customerId;
        public String name;
        public String accountType; // 'Savings' or 'Current'
        public Decimal balance;
        public BankCustomerProfile(String customerId, String name, String accountType, Decimal initialDeposit) {
            if (initialDeposit < 1000) {
                throw new IllegalArgumentException('Initial deposit must be at least ₹1000');
            }
            this.customerId = customerId;
            this.name = name;
            this.accountType = accountType;
            this.balance = initialDeposit;
        }
        public void deposit(Decimal amount) {
            this.balance += amount;
        }
        public Decimal getBalance() {
            return balance;
        }
    }
    //  Employee record
    public class BankEmployeeRecord {//can use getter and setter in place of name and role
        public String employeeId;
        public String name;
        public String role;
        public BankEmployeeRecord(String employeeId, String name, String role) {
            this.employeeId = employeeId;
            this.name = name;
            this.role = role;
        }
        public String getDetails() {
            return 'Employee: ' + name + ', Role: ' + role;
        }
    }
    //  Loan application
    public class BankLoanApplication {
        public String loanId;
        public BankCustomerProfile applicant;
        public Decimal amount;
        public Integer termMonths;
        public Decimal interestRate;
        public BankLoanApplication(String loanId, BankCustomerProfile applicant, Decimal amount, 
                                   Integer termMonths, Decimal interestRate) {
            this.loanId = loanId;
            this.applicant = applicant;
            this.amount = amount;
            this.termMonths = termMonths;
            this.interestRate = interestRate;
        }
        public Decimal calculateMonthlyPayment() {
            Double principal = Double.valueOf(amount);
            Double monthlyRate = Double.valueOf(interestRate) / 12 / 100;
            Double months = Double.valueOf(termMonths);
            Double denominator = 1 - Math.pow(1 + monthlyRate, -months);
            Double monthlyPayment = (principal * monthlyRate) / denominator;
            System.debug('Monthly Loan Payment for ' + applicant.name + ': ₹' + Decimal.valueOf(monthlyPayment).setScale(2));
            return Decimal.valueOf(monthlyPayment).setScale(2);
        }
    }
    //  Top-level static method for demo execution
    public static void runDemo() {
        BankCustomerProfile savingsCustomer = new BankCustomerProfile('CUST001', 'Aarav Mehta', 'Savings', 1000);
        BankCustomerProfile currentCustomer = new BankCustomerProfile('CUST002', 'Neha Sharma', 'Current', 1000);

        savingsCustomer.deposit(5000);
        currentCustomer.deposit(3000);

        System.debug(savingsCustomer.name + ' (' + savingsCustomer.accountType + ') Balance: ₹' + savingsCustomer.getBalance().setScale(2));
        System.debug(currentCustomer.name + ' (' + currentCustomer.accountType + ') Balance: ₹' + currentCustomer.getBalance().setScale(2));

        BankLoanApplication loan = new BankLoanApplication(
            'LOAN001',
            savingsCustomer,
            200000,
            24,
            8.5
        );
        Decimal monthlyPayment = loan.calculateMonthlyPayment();
    }
}