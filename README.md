# 📚 Conditional Social Program Payments

A smart contract system for distributing conditional cash transfers based on school attendance. Families receive monthly allowances when their children maintain minimum attendance rates at school.

## 🌟 Features

- 👨‍👩‍👧‍👦 **Family Registration**: Register families and their children in the program
- 📅 **Attendance Tracking**: Record and verify school attendance for each child  
- 💰 **Conditional Payments**: Automatic monthly payments based on attendance requirements
- 👨‍💼 **Admin Controls**: Program management and configuration settings
- 📊 **Payment History**: Track all payments and family records

## 🎯 How It Works

1. **Admin registers families** with their children count
2. **Children are enrolled** with school information
3. **Attendance is recorded** monthly for each child
4. **Payments are processed** automatically if attendance meets minimum requirements (default 80%)
5. **Families receive STX** directly to their wallets

## ⚙️ Configuration

- **Monthly Allowance**: 1 STX per child (configurable)
- **Minimum Attendance**: 80% required (configurable)  
- **Payment Period**: 4320 blocks (~30 days)

## 🚀 Usage

### Register a Family
```clarity
(contract-call? .conditional-social-program-payments register-family 'SP1EXAMPLE... u2)
```

### Register a Child
```clarity
(contract-call? .conditional-social-program-payments register-child u1 "Alice Smith" u8 "Jefferson Elementary")
```

### Record Attendance
```clarity
(contract-call? .conditional-social-program-payments record-attendance u1 u11 u2024 u18 u20)
```

### Process Monthly Payment
```clarity
(contract-call? .conditional-social-program-payments process-monthly-payment u1 u11 u2024)
```

### Check Family Status
```clarity
(contract-call? .conditional-social-program-payments get-family u1)
```

### Check Program Settings
```clarity
(contract-call? .conditional-social-program-payments get-program-status)
```

## 📋 Contract Functions

### Read-Only Functions
- `get-family(family-id)` - Get family information
- `get-child(child-id)` - Get child information  
- `get-attendance(child-id, month, year)` - Get attendance record
- `get-program-status()` - Get current program configuration
- `calculate-attendance-rate(child-id, month, year)` - Calculate attendance percentage
- `is-eligible-for-payment(family-id, month, year)` - Check payment eligibility

### Public Functions
- `register-family(head, children-count)` - Register new family (admin only)
- `register-child(family-id, name, age, school)` - Register new child (admin only)
- `record-attendance(child-id, month, year, days-attended, total-days)` - Record attendance (admin only)
- `process-monthly-payment(family-id, month, year)` - Process conditional payment
- `update-program-settings(active, allowance, min-attendance)` - Update program config (admin only)
- `deactivate-family(family-id)` - Deactivate family from program (admin only)

## 🛡️ Security Features

- **Owner-only administration** for sensitive functions
- **Attendance validation** ensures realistic attendance records
- **Payment eligibility checks** prevent duplicate or invalid payments
- **Family and child validation** prevents orphaned records

## 📦 Installation

1. Clone the repository
2. Install Clarinet: `npm install -g @hirosystems/clarinet`
3. Deploy contract: `clarinet deploy --testnet`

## 🧪 Testing

Run the test suite:
```bash
clarinet test
```

## 💡 Example Scenario

A family with 2 children receives 2 STX monthly if both children maintain 80%+ attendance. If one child has 75% attendance, the family receives no payment that month.

## 🤝 Contributing

Feel free to submit issues and pull requests to improve the conditional payment system!

## 📄 License

MIT License - see LICENSE file for details.
