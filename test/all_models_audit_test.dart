import 'package:flutter_test/flutter_test.dart';
import 'package:laundrypro_uae/core/money_utils.dart';
import 'package:laundrypro_uae/core/phone_normalizer.dart';
import 'package:laundrypro_uae/core/safe_parser.dart';
import 'package:laundrypro_uae/core/validators.dart';

// Models
import 'package:laundrypro_uae/models/attendance_model.dart';
import 'package:laundrypro_uae/models/branch_model.dart';
import 'package:laundrypro_uae/models/cart_line_model.dart';
import 'package:laundrypro_uae/models/challan_model.dart';
import 'package:laundrypro_uae/models/customer_model.dart';
import 'package:laundrypro_uae/models/dashboard_metrics_model.dart';
import 'package:laundrypro_uae/models/delivery_model.dart';
import 'package:laundrypro_uae/models/employee_model.dart';
import 'package:laundrypro_uae/models/garment_tag_model.dart';
import 'package:laundrypro_uae/models/inventory_model.dart';
import 'package:laundrypro_uae/models/invoice_model.dart';
import 'package:laundrypro_uae/models/leave_model.dart';
import 'package:laundrypro_uae/models/order_item_model.dart';
import 'package:laundrypro_uae/models/order_model.dart';
import 'package:laundrypro_uae/models/payment_model.dart';
import 'package:laundrypro_uae/models/payroll_model.dart';
import 'package:laundrypro_uae/models/purchase_order_model.dart';
import 'package:laundrypro_uae/models/report_config_model.dart';
import 'package:laundrypro_uae/models/salary_advance_model.dart';
import 'package:laundrypro_uae/models/service_model.dart';
import 'package:laundrypro_uae/models/sync_entry_model.dart';
import 'package:laundrypro_uae/models/user_model.dart';
import 'package:laundrypro_uae/models/vendor_model.dart';

void main() {
  group('Core Math & Parsing Edge Cases', () {
    test('MoneyUtils UAE 5% VAT calculations & rounding', () {
      expect(MoneyUtils.roundHalfUp(10.555), 10.56);
      expect(MoneyUtils.roundHalfUp(10.554), 10.55);
      
      // Exclusive VAT on 100 AED
      expect(MoneyUtils.calculateVatExclusive(100.0), 5.0);
      expect(MoneyUtils.addVat(100.0), 105.0);

      // Inclusive VAT on 105 AED
      expect(MoneyUtils.calculateVatInclusive(105.0), 5.0);
    });

    test('SafeParser handles dirty / unexpected API types', () {
      expect(SafeParser.parseInt(null, 10), 10);
      expect(SafeParser.parseInt('42'), 42);
      expect(SafeParser.parseInt(42.9), 42);
      expect(SafeParser.parseInt('invalid', 99), 99);

      expect(SafeParser.parseDouble(null, 3.14), 3.14);
      expect(SafeParser.parseDouble('99.95'), 99.95);
      expect(SafeParser.parseDouble(100), 100.0);
      expect(SafeParser.parseDouble('abc', 0.0), 0.0);

      final fallback = DateTime(2026, 1, 1);
      expect(SafeParser.parseDateTime(null, fallback: fallback), fallback);
      expect(SafeParser.parseDateTime('not-a-date', fallback: fallback), fallback);
      expect(SafeParser.parseDateTime('2026-10-25T12:00:00Z').year, 2026);
    });

    test('PhoneNormalizer handles international and local UAE numbers', () {
      expect(PhoneNormalizer.normalizeUaePhone('+971 50 123 4567'), '0501234567');
      expect(PhoneNormalizer.normalizeUaePhone('00971501234567'), '0501234567');
      expect(PhoneNormalizer.normalizeUaePhone('971501234567'), '0501234567');
      expect(PhoneNormalizer.normalizeUaePhone('050-123-4567'), '0501234567');
      expect(PhoneNormalizer.normalizeUaePhone('501234567'), '0501234567');
      expect(PhoneNormalizer.normalizeUaePhone(''), '');
      
      expect(PhoneNormalizer.levenshtein('Dubai', 'Dubai'), 0);
      expect(PhoneNormalizer.levenshtein('Dubai', 'Dubia'), 2);
    });

    test('Validators enforce UAE format requirements', () {
      expect(Validators.email('test@uaelaundry.ae'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);

      expect(Validators.uaePhone('+971501234567'), isNull);
      expect(Validators.uaePhone('0501234567'), isNull);
      expect(Validators.uaePhone('0551234567'), isNull);
      expect(Validators.uaePhone('12345'), isNotNull);

      // 15 digits UAE TRN
      expect(Validators.uaeTrn('100492817200003'), isNull);
      expect(Validators.uaeTrn('12345'), isNotNull);
      expect(Validators.uaeTrn(null), isNull); // Optional
    });
  });

  group('All Data Models fromJson / toJson Audit', () {
    test('AttendanceModel serialization', () {
      final model = AttendanceModel.fromJson({
        'id': 1,
        'uuid': 'ATT-001',
        'employee_id': 10,
        'date': '2026-10-25',
        'status': 'present',
        'check_in': '08:00:00',
        'check_out': '17:00:00',
      });
      expect(model.employeeId, 10);
      expect(model.status, 'present');
      expect(model.checkIn, '08:00:00');
      expect(model.toJson()['status'], 'present');
    });

    test('BranchModel serialization', () {
      final model = BranchModel.fromJson({
        'id': 1,
        'uuid': 'BR-01',
        'name': 'Dubai Marina Branch',
        'location': 'Dubai Marina',
        'is_active': 1,
        'created_at': '2026-01-01',
      });
      expect(model.uuid, 'BR-01');
      expect(model.isActive, true);
      expect(model.toJson()['name'], 'Dubai Marina Branch');
    });

    test('CartLine item calculations', () {
      final line = CartLine(
        itemType: 'service',
        itemId: 101,
        name: 'Dry Clean Suit',
        rate: 50.0,
        quantity: 2,
        discount: 5.0,
      );
      expect(line.lineSubtotal, 100.0);
      expect(line.lineTotal, 95.0);
      final json = line.toLine();
      expect(json['description'], 'Dry Clean Suit');
      expect(json['rate'], 50.0);
    });

    test('ChallanModel serialization', () {
      final challan = ChallanModel.fromMap({
        'id': 5,
        'challan_no': 'CH-900',
        'customer_id': 20,
        'status': 'issued',
        'lines': [
          {'description': 'Towels', 'quantity': 10},
        ],
        'created_at': '2026-10-25T10:00:00',
      });
      expect(challan.challanNo, 'CH-900');
      expect(challan.lines.length, 1);
    });

    test('CustomerModel serialization and full details', () {
      final customer = CustomerModel.fromJson({
        'id': 1,
        'uuid': 'CUST-001',
        'name': 'Mohammed Al Maktoum',
        'phone': '0501234567',
        'email': 'm@uae.ae',
        'trn': '100492817200003',
        'balance': 250.0,
        'created_at': '2026-10-25T10:00:00',
      });
      expect(customer.name, 'Mohammed Al Maktoum');
      expect(customer.trn, '100492817200003');
      expect(customer.customerCode, 'CUST-001');
      expect(customer.toJson()['name'], 'Mohammed Al Maktoum');
    });

    test('DashboardMetricsModel serialization', () {
      final metrics = DashboardMetricsModel.fromJson({
        'sales_total': 12500.50,
        'order_count': 45,
        'pending_count': 5,
        'ready_count': 12,
        'delivered_count': 28,
      });
      expect(metrics.salesTotal, 12500.50);
      expect(metrics.orderCount, 45);
      expect(metrics.toJson()['sales_total'], 12500.50);
    });

    test('DeliveryModel status flow and serialization', () {
      final delivery = DeliveryModel.fromJson({
        'id': 1,
        'uuid': 'DEL-UUID-1',
        'order_id': 200,
        'driver_id': 7,
        'status': 'dispatched',
        'address': 'Downtown Dubai Apt 401',
        'created_at': '2026-10-25T11:00:00',
      });
      expect(delivery.driverId, 7);
      expect(delivery.driverName, 'Driver #7');
      expect(delivery.status, 'dispatched');
      expect(delivery.toJson()['address'], 'Downtown Dubai Apt 401');
    });

    test('EmployeeModel UAE compliance fields', () {
      final employee = EmployeeModel.fromJson({
        'id': 1,
        'uuid': 'EMP-UUID-1',
        'employee_no': 'EMP-01',
        'full_name': 'Ahmed Mansoor',
        'job_title': 'Senior Presser',
        'department': 'Operations',
        'base_salary': 4000.0,
        'civil_id': '784-1990-1234567-1',
        'passport_no': 'N1234567',
        'is_active': 1,
      });
      expect(employee.fullName, 'Ahmed Mansoor');
      expect(employee.civilId, '784-1990-1234567-1');
      expect(employee.passportNo, 'N1234567');
      expect(employee.toJson()['employee_no'], 'EMP-01');
    });

    test('GarmentTagModel RFID and barcode tracking', () {
      final tag = GarmentTagModel.fromJson({
        'id': 1,
        'uuid': 'TAG-UUID-1',
        'rfid_epc': 'E280116060000204',
        'barcode': 'BC-9901',
        'order_item_id': 100,
        'status': 'washing',
        'created_at': '2026-10-25T09:00:00',
        'updated_at': '2026-10-25T09:00:00',
      });
      expect(tag.barcode, 'BC-9901');
      expect(tag.rfidEpc, 'E280116060000204');
      expect(tag.status, 'washing');
      expect(tag.toJson()['status'], 'washing');
    });

    test('InventoryModel stock and valuation', () {
      final item = InventoryModel.fromJson({
        'id': 1,
        'uuid': 'INV-UUID-1',
        'item_name': 'Liquid Detergent 20L',
        'sku': 'DET-001',
        'quantity': 15,
        'unit_price': 120.0,
        'reorder_level': 5,
        'created_at': '2026-10-25T08:00:00',
        'updated_at': '2026-10-25T08:00:00',
      });
      expect(item.sku, 'DET-001');
      expect(item.quantity, 15);
      expect(item.reorderLevel, 5);
      expect(item.toJson()['sku'], 'DET-001');
    });

    test('InvoiceModel VAT and totals parsing', () {
      final inv = InvoiceModel.fromJson({
        'id': 1,
        'uuid': 'INV-UUID-1',
        'invoice_number': 'INV-2026-001',
        'order_id': 50,
        'customer_id': 12,
        'subtotal': 200.0,
        'vat_amount': 10.0,
        'total_amount': 210.0,
        'status': 'paid',
        'is_posted': 1,
        'created_at': '2026-10-25T11:30:00',
      });
      expect(inv.invoiceNumber, 'INV-2026-001');
      expect(inv.vatAmount, 10.0);
      expect(inv.totalAmount, 210.0);
      expect(inv.status, 'paid');
      expect(inv.isPosted, true);
    });

    test('LeaveModel approval and dates', () {
      final leave = LeaveModel.fromJson({
        'id': 1,
        'employee_id': 5,
        'leave_type': 'annual',
        'start_date': '2026-11-01',
        'end_date': '2026-11-10',
        'status': 'approved',
        'created_at': '2026-10-25T10:00:00',
      });
      expect(leave.durationDays, 10);
      expect(leave.status, 'approved');
      expect(leave.toJson()['leave_type'], 'annual');
    });

    test('OrderItemModel service & garment serialization', () {
      final item = OrderItemModel.fromJson({
        'id': 1,
        'order_id': 10,
        'service_id': 2,
        'service_name': 'Wash & Fold',
        'quantity': 3.0,
        'unit_price': 15.0,
        'total_price': 45.0,
      });
      expect(item.serviceName, 'Wash & Fold');
      expect(item.quantity, 3.0);
      expect(item.totalPrice, 45.0);
      expect(item.toJson()['service_id'], 2);
    });

    test('OrderModel full lifecycle mapping', () {
      final order = OrderModel.fromJson({
        'id': 1,
        'uuid': 'ORD-UUID-1',
        'order_no': 'LP-2026-0001',
        'customer_id': 2,
        'status': 'confirmed',
        'payment_status': 'unpaid',
        'subtotal': 100.0,
        'vat_amount': 5.0,
        'grand_total': 105.0,
        'items': [
          {'id': 1, 'service_id': 2, 'service_name': 'Wash', 'quantity': 1, 'unit_price': 100, 'total_price': 100}
        ],
        'created_at': '2026-10-25T10:00:00',
      });
      expect(order.orderNo, 'LP-2026-0001');
      expect(order.items.length, 1);
      expect(order.grandTotal, 105.0);
      expect(order.toJson()['order_no'], 'LP-2026-0001');
    });

    test('PaymentModel methods and verification', () {
      final payment = PaymentModel.fromJson({
        'id': 1,
        'uuid': 'PAY-UUID-1',
        'order_id': 10,
        'method': 'card',
        'amount': 105.0,
        'transaction_reference': 'AUTH-789012',
        'status': 'completed',
        'created_at': '2026-10-25T10:05:00',
      });
      expect(payment.method, 'card');
      expect(payment.amount, 105.0);
      expect(payment.transactionReference, 'AUTH-789012');
      expect(payment.toJson()['status'], 'completed');
    });

    test('PayrollModel & PayrollRunModel UAE WPS SIF structure', () {
      final run = PayrollRunModel.fromJson({
        'id': 1,
        'payroll_period_id': 1,
        'run_no': 'PR-2026-09',
        'total_amount': 25000.0,
        'status': 'approved',
        'lines': [
          {
            'id': 1,
            'payroll_run_id': 1,
            'employee_id': 1,
            'employee_no': 'EMP-01',
            'employee_name': 'Ali',
            'base_salary': 4000.0,
            'allowances': 2000.0,
            'advance_deduction': 100.0,
            'net_pay': 5900.0,
          }
        ],
      });
      expect(run.runNo, 'PR-2026-09');
      expect(run.lines.length, 1);
      expect(run.lines.first.netPay, 5900.0);
      expect(run.lines.first.grossPay, 6000.0);
      expect(run.toJson()['status'], 'approved');
    });

    test('PurchaseOrderModel PO creation and receiving', () {
      final po = PurchaseOrderModel.fromJson({
        'id': 1,
        'uuid': 'PO-UUID-1',
        'po_no': 'PO-8812',
        'vendor_id': 3,
        'total_amount': 1050.0,
        'status': 'ordered',
        'lines': [
          {
            'id': 1,
            'purchase_order_id': 1,
            'line_no': 1,
            'product_id': 10,
            'product_name': 'Fabric Softener',
            'quantity_ordered': 10.0,
            'quantity_received': 0.0,
            'unit_cost': 100.0,
          }
        ],
        'created_at': '2026-10-25T08:00:00',
        'updated_at': '2026-10-25T08:00:00',
      });
      expect(po.poNo, 'PO-8812');
      expect(po.totalAmount, 1050.0);
      expect(po.lines.length, 1);
      expect(po.lines.first.isFullyReceived, false);
      expect(po.toJson()['po_no'], 'PO-8812');
    });

    test('ReportConfigModel dates and branch scoping', () {
      const config = ReportConfigModel(
        fromDate: '2026-09-01',
        toDate: '2026-09-30',
        branchId: 1,
        metric: 'sales_total',
      );
      expect(config.metric, 'sales_total');
      expect(config.branchId, 1);
      final json = config.toJson();
      expect(json['metric'], 'sales_total');
      expect(json['branch_id'], 1);
    });

    test('SalaryAdvanceModel balance calculation', () {
      final adv = SalaryAdvanceModel.fromJson({
        'id': 1,
        'employee_id': 2,
        'amount': 1000.0,
        'balance_remaining': 600.0,
        'status': 'active',
        'request_date': '2026-10-01',
      });
      expect(adv.amount, 1000.0);
      expect(adv.balanceRemaining, 600.0);
      expect(adv.currentBalance, 600.0);
      expect(adv.toJson()['status'], 'active');
    });

    test('ServiceModel pricing and category', () {
      final svc = ServiceModel.fromJson({
        'id': 1,
        'uuid': 'SVC-UUID-1',
        'category_id': 2,
        'name': 'Suit Express Clean',
        'price': 45.0,
        'is_active': 1,
        'created_at': '2026-10-25T08:00:00',
      });
      expect(svc.name, 'Suit Express Clean');
      expect(svc.price, 45.0);
      expect(svc.baseRate, 45.0);
      expect(svc.toJson()['name'], 'Suit Express Clean');
    });

    test('SyncEntryModel queue payload and status', () {
      final entry = SyncEntryModel.fromJson({
        'id': 1,
        'entity_type': 'order',
        'entity_id': '10',
        'action': 'insert',
        'payload': '{"order_no": "ORD-1"}',
        'status': 'pending',
        'sync_attempts': 0,
        'created_at': '2026-10-25T11:00:00',
      });
      expect(entry.entityType, 'order');
      expect(entry.status, 'pending');
      expect(entry.action, 'insert');
      expect(entry.toJson()['action'], 'insert');
    });

    test('UserModel roles and permission queries', () {
      const admin = UserModel(
        id: 1,
        uuid: 'U-ADMIN',
        username: 'superadmin',
        fullName: 'Chief Administrator',
        email: 'admin@uaelaundry.ae',
        role: 'system_admin',
        permissions: ['*'],
      );
      expect(admin.isAdmin, true);
      expect(admin.hasPermission('sales.create'), false);
      expect(admin.hasPermission('*'), true);

      const cashier = UserModel(
        id: 2,
        uuid: 'U-CASHIER',
        username: 'cashier1',
        fullName: 'Zayd Cashier',
        email: null,
        role: 'cashier',
        permissions: ['sales.create', 'sales.receive_payment'],
      );
      expect(cashier.isAdmin, false);
      expect(cashier.hasPermission('sales.create'), true);
      expect(cashier.hasPermission('system.config.paths'), false);
      expect(cashier.canEditGlobalConfig, false);
    });

    test('VendorModel serialization', () {
      final vendor = VendorModel.fromJson({
        'id': 1,
        'name': 'Diversey UAE Supplies',
        'contact_person': 'Karim',
        'phone': '0501112233',
        'email': 'karim@diversey.ae',
        'trn': '100492817200003',
        'is_active': 1,
      });
      expect(vendor.name, 'Diversey UAE Supplies');
      expect(vendor.phone, '0501112233');
      expect(vendor.toJson()['name'], 'Diversey UAE Supplies');
    });
  });
}
