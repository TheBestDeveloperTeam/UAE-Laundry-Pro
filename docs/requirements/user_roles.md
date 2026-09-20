# User Roles & Permissions - LaundryPro UAE
> **Version:** 1.0.0

## Role Hierarchy
super_admin > owner > manager > cashier / operator / driver

## Permission Matrix
| Module | Action | super_admin | owner | manager | cashier | operator | driver |
|--------|--------|:-----------:|:-----:|:-------:|:-------:|:--------:|:------:|
| Auth | Login | Y | Y | Y | Y | Y | Y |
| Auth | Manage Users | Y | Y | N | N | N | N |
| Orders | Create | Y | Y | Y | Y | N | N |
| Orders | View All | Y | Y | Y | N | N | N |
| Orders | View Own | Y | Y | Y | Y | Y | Y |
| POS | Process Payment | Y | Y | Y | Y | N | N |
| POS | Void Transaction | Y | Y | Y | N | N | N |
| Inventory | View | Y | Y | Y | N | Y | N |
| Inventory | Modify | Y | Y | Y | N | N | N |
| Production | Update Status | Y | Y | Y | N | Y | N |
| Delivery | Assign Driver | Y | Y | Y | N | N | N |
| Delivery | Update Status | Y | Y | Y | N | N | Y |
| Customers | View | Y | Y | Y | Y | N | N |
| Customers | Modify | Y | Y | Y | N | N | N |
| HR | View Employees | Y | Y | Y | N | N | N |
| HR | Manage Payroll | Y | Y | N | N | N | N |
| Finance | View Reports | Y | Y | Y | N | N | N |
| Finance | Manage Invoices | Y | Y | N | N | N | N |
| Settings | Configure | Y | Y | N | N | N | N |
| Settings | Manage Branches | Y | Y | N | N | N | N |
| System | Backup/Restore | Y | Y | N | N | N | N |
| System | License Mgmt | Y | N | N | N | N | N |