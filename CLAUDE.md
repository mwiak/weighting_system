# CLAUDE.md - Flutter Truck Weighing System

## Project Overview
A comprehensive Flutter desktop application for truck weighing systems with Odoo ERP integration, designed for Windows environments with industrial weighbridge operations.

## Architecture & Technologies
- **Framework**: Flutter Desktop (Windows target)
- **UI Library**: Fluent UI (Windows native design)
- **Database**: SQLite with sqflite_common_ffi for desktop support
- **State Management**: Provider pattern
- **Serial Communication**: Windows COM port via win32 FFI
- **ERP Integration**: Odoo Community Edition via REST API
- **PDF Generation**: pdf & printing packages
- **Localization**: Flutter intl support

## Current Status
✅ **Completed Features:**
- Project structure and dependencies
- SQLite database schema with all tables
- Data models with JSON serialization
- Serial communication for weight reading (COM4)
- State management providers (Weight, Order, Sync, Client, Material, Print, Report)
- Main dashboard with Fluent UI
- Weight reading with real-time display
- Order management system
- Client and supplier management
- Material management system
- Odoo integration and sync functionality
- Professional printing system (invoices/tickets)
- Comprehensive reporting and analytics

🔄 **Pending Features:**
- Offline mode and synchronization queue
- Localization support (English, Turkish, Arabic)
- Security and access control
- Configuration management
- Deployment package and installer

## Known Issues & Considerations

### Error Fixes Applied ✅
**All critical errors have been resolved. The following fixes were applied:**

1. **Dependencies**: Added missing `path` and `pdf` packages to pubspec.yaml
2. **FluentIcons**: Fixed `FluentIcons.office_building` → `FluentIcons.city_next` and `FluentIcons.printer` → `FluentIcons.print`
3. **DataTable**: Replaced non-compatible DataTable with custom table using Container/Row layout
4. **SplitButton**: Replaced with DropDownButton for better Fluent UI compatibility
5. **Missing Methods**: Added `getClientById()` and `getMaterialById()` methods to providers
6. **Imports**: Removed unused imports and added missing model imports
7. **Print Statements**: Replaced all `print()` with `debugPrint()` for production compatibility
8. **Type Issues**: Fixed int to string conversion in report service SQL parameters
9. **Null Safety**: Fixed unnecessary null assertions and improved null safety
10. **Unused Variables**: Removed unused variables and fields

**Current Status**: 0 errors, 101 warnings/info messages (mostly style suggestions)

### 1. Flutter Layout Incompatibilities

⚠️ **CRITICAL**: For widget that do not have height constraint, do not put a widget that does not have height constraint in its children. Specify height constraint to avoid vertical port unbounded height exception.

**Issue**: Fluent UI API changes and deprecated widgets
```dart
// ❌ Deprecated - Don't use
NavigationPaneItem()
FilledButton.icon()
Button.icon()
ListTile(onTap: )

// ✅ Use instead
PaneItem()
FilledButton(child: Row(children: [Icon(), Text()]))
Button(child: Row(children: [Icon(), Text()]))
ListTile.selectable(onSelectionChange: )
```

**Missing Icons**: Some FluentIcons don't exist
```dart
// ❌ Non-existent
FluentIcons.check_mark_circle
FluentIcons.package_fill
FluentIcons.vehicle_truck

// ✅ Use alternatives
FluentIcons.accept
FluentIcons.package
FluentIcons.bus
```

**Connectivity API**: Handle List vs single result
```dart
// ❌ Old API
List<ConnectivityResult> results = await connectivity.checkConnectivity();

// ✅ Current API
ConnectivityResult result = await connectivity.checkConnectivity();
```

### 2. Odoo Integration - Standard Models Only

⚠️ **CRITICAL**: Do not create custom Odoo models. Use only standard Odoo Community Edition models.

#### Sales Operations (Loading/Outgoing)
```dart
// When net_weight > 0 and operation_type = 'loading'
// Create sale.order entry in Odoo
{
  'partner_id': client.odoo_id,
  'order_line': [{
    'product_id': material.odoo_id, 
    'product_uom_qty': net_weight_in_tons, // Convert kg to tons
    'price_unit': material.list_price,
    'name': 'Weighing Order: ${order.order_number}',
  }],
  'origin': order.order_number,
  'note': 'Generated from Truck Weighing System',
  'state': 'draft', // Let sales team confirm
}
```

#### Purchase Operations (Unloading/Incoming)
```dart
// When net_weight > 0 and operation_type = 'unloading' 
// Create purchase.order entry in Odoo
{
  'partner_id': supplier.odoo_id,
  'order_line': [{
    'product_id': material.odoo_id,
    'product_qty': net_weight_in_tons, // Convert kg to tons  
    'price_unit': material.standard_price,
    'name': 'Weighing Order: ${order.order_number}',
  }],
  'origin': order.order_number,
  'notes': 'Generated from Truck Weighing System',
  'state': 'draft', // Let purchase team confirm
}
```

#### Standard Odoo Models to Use
```dart
// Partners (Clients & Suppliers)
'res.partner' => {
  'name': required,
  'is_company': true/false,
  'customer_rank': 1, // For clients
  'supplier_rank': 1, // For suppliers  
  'email': optional,
  'phone': optional,
  'street': optional,
  'city': optional,
  'zip': optional,
  'vat': optional,
}

// Products (Materials)
'product.product' => {
  'name': required,
  'default_code': optional, // Internal reference
  'barcode': optional,
  'list_price': for_sales,
  'standard_price': for_purchases,
  'type': 'product', // stockable
  'tracking': 'none'|'lot'|'serial',
  'categ_id': 1, // All / Saleable or All / Purchased
  'uom_id': 1, // Units
  'uom_po_id': 1, // Purchase UoM
}

// Sale Orders (for loading operations)  
'sale.order' => {
  'partner_id': client.odoo_id,
  'origin': order.order_number,
  'note': weighing_details,
  'state': 'draft',
}

// Purchase Orders (for unloading operations)
'purchase.order' => {
  'partner_id': supplier.odoo_id, 
  'origin': order.order_number,
  'notes': weighing_details,
  'state': 'draft',
}
```

### 3. Database Schema Corrections

#### Database altering - Do not use onUpgrade, instead alter the onCreate table schemas and prompt the user to delete the old db. 

#### Orders Table - Remove Custom Odoo Dependencies
```sql
-- ❌ Don't sync orders directly to custom odoo model
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number TEXT UNIQUE NOT NULL,
  operation_type TEXT NOT NULL, -- 'loading', 'unloading' 
  client_id INTEGER REFERENCES clients(id),
  supplier_id INTEGER REFERENCES suppliers(id), 
  material_id INTEGER REFERENCES materials(id),
  truck_plate TEXT,
  driver_name TEXT,
  driver_license TEXT,
  gross_weight REAL DEFAULT 0,
  tare_weight REAL DEFAULT 0, 
  net_weight REAL DEFAULT 0,
  unit_price REAL DEFAULT 0,
  total_amount REAL DEFAULT 0,
  status TEXT DEFAULT 'draft', -- draft, active, completed, cancelled
  weigh_in_time TEXT,
  weigh_out_time TEXT,
  notes TEXT,
  create_date TEXT DEFAULT CURRENT_TIMESTAMP,
  write_date TEXT DEFAULT CURRENT_TIMESTAMP,
  -- Remove odoo_id field - orders don't sync directly
  sync_status INTEGER DEFAULT 0, -- 0=pending, 1=synced, 2=error
  sale_order_id INTEGER, -- Reference to created sale.order in Odoo
  purchase_order_id INTEGER, -- Reference to created purchase.order in Odoo
);
```

### 4. Sync Strategy Corrections

#### Order Completion Sync Logic
```dart
Future<void> _syncCompletedOrder(Order order) async {
  if (order.status != 'completed' || order.netWeight <= 0) return;
  
  try {
    if (order.operationType == 'loading') {
      // Create sale order
      final saleOrderData = {
        'partner_id': order.clientId, // Must have odoo_id
        'origin': order.orderNumber,
        'order_line': [(0, 0, {
          'product_id': order.materialId, // Must have odoo_id
          'product_uom_qty': order.netWeight / 1000, // kg to tons
          'price_unit': order.unitPrice ?? 0,
          'name': 'Weighing Order: ${order.orderNumber}',
        })],
        'note': _buildOrderNotes(order),
        'state': 'draft',
      };
      
      final saleOrderId = await _odooService.call('sale.order', 'create', [saleOrderData]);
      
      // Update local order with Odoo reference  
      await _db.update('orders', {
        'sale_order_id': saleOrderId,
        'sync_status': 1,
      }, where: 'id = ?', whereArgs: [order.id]);
      
    } else if (order.operationType == 'unloading') {
      // Create purchase order
      final purchaseOrderData = {
        'partner_id': order.supplierId, // Must have odoo_id
        'origin': order.orderNumber,
        'order_line': [(0, 0, {
          'product_id': order.materialId, // Must have odoo_id  
          'product_qty': order.netWeight / 1000, // kg to tons
          'price_unit': order.unitPrice ?? 0,
          'name': 'Weighing Order: ${order.orderNumber}',
        })],
        'notes': _buildOrderNotes(order),
        'state': 'draft',
      };
      
      final purchaseOrderId = await _odooService.call('purchase.order', 'create', [purchaseOrderData]);
      
      // Update local order with Odoo reference
      await _db.update('orders', {
        'purchase_order_id': purchaseOrderId, 
        'sync_status': 1,
      }, where: 'id = ?', whereArgs: [order.id]);
    }
  } catch (e) {
    // Mark sync as failed
    await _db.update('orders', {
      'sync_status': 2,
    }, where: 'id = ?', whereArgs: [order.id]);
    rethrow;
  }
}

String _buildOrderNotes(Order order) {
  return '''
Truck Weighing Details:
- Order Number: ${order.orderNumber}
- Truck Plate: ${order.truckPlate}
- Driver: ${order.driverName}
- Gross Weight: ${order.grossWeight?.toStringAsFixed(2)} kg
- Tare Weight: ${order.tareWeight?.toStringAsFixed(2)} kg  
- Net Weight: ${order.netWeight?.toStringAsFixed(2)} kg
- Weigh In: ${order.weighInTime}
- Weigh Out: ${order.weighOutTime}
${order.notes != null ? '\nNotes: ${order.notes}' : ''}
''';
}
```

### 5. Development Commands

#### Build & Run
```bash
# Development
flutter run -d windows

# Build release
flutter build windows --release

# Generate code (for JSON serialization)
flutter packages pub run build_runner build

# Clean build
flutter clean
flutter pub get
```

#### Database Reset (Development)
```dart
// Add to DatabaseHelper for development only
Future<void> resetDatabase() async {
  final db = await database;
  await db.execute('DROP TABLE IF EXISTS orders');
  await db.execute('DROP TABLE IF EXISTS clients'); 
  await db.execute('DROP TABLE IF EXISTS suppliers');
  await db.execute('DROP TABLE IF EXISTS materials');
  await db.execute('DROP TABLE IF EXISTS sync_queue');
  await _createTables(db, 1);
}
```

### 6. Common Errors & Solutions

#### FluentUI DataTable Issues
```dart
// ❌ DataTable doesn't work well with Fluent UI
DataTable(columns: [...], rows: [...])

// ✅ Use ListView with ListTile.selectable instead
ListView.builder(
  itemBuilder: (context, index) => ListTile.selectable(
    title: Text(data[index].title),
    subtitle: Text(data[index].subtitle),
    onSelectionChange: (selected) => handleSelection(selected, data[index]),
  ),
)
```

#### Serial Port Access Errors
```dart
// Ensure proper COM port permissions
// Run Flutter app as Administrator if needed
// Check Windows Device Manager for correct COM port
```

#### Odoo Authentication Issues
```dart
// Always check authentication before API calls
if (!_odooService.isAuthenticated) {
  final authSuccess = await _odooService.authenticate();
  if (!authSuccess) throw Exception('Odoo authentication failed');
}
```

### 7. Testing Strategy

#### Unit Tests
- Database operations
- Data model serialization
- Business logic calculations  
- Odoo service methods

#### Integration Tests  
- Serial communication
- Odoo API integration
- PDF generation
- Export functionality

#### UI Tests
- Navigation flows
- Form validation
- Data display
- Print actions

### 8. Deployment Notes

#### Windows Installer
- Use MSIX for Windows Store distribution
- Or create installer with Inno Setup
- Include Visual C++ Redistributables
- Test on clean Windows machines

#### Configuration Files
- Store Odoo credentials securely
- Allow COM port configuration
- Backup/restore database functionality
- Update mechanism

### 9. Security Considerations

#### Data Protection
- Encrypt sensitive database fields
- Secure Odoo credentials storage
- Implement user authentication
- Audit trail for critical operations

#### Network Security  
- HTTPS only for Odoo communication
- Certificate validation
- Rate limiting for API calls
- Error message sanitization

### 10. Maintenance Tasks

#### Regular Maintenance
- Database cleanup/optimization
- Sync queue monitoring  
- Log file rotation
- Performance monitoring

#### Updates
- Flutter SDK updates
- Dependency updates  
- Odoo compatibility checks
- Windows compatibility testing

## Next Development Steps

1. **Implement offline mode** with local queue
2. **Add localization** for multi-language support
3. **Enhance security** with user roles and permissions
4. **Create installer** for easy deployment
5. **Add configuration UI** for system settings

## Important Notes

- Always test Odoo integration with Community Edition
- Never create custom Odoo models - use standard sales/purchase flows
- Handle Flutter desktop quirks and API changes
- Maintain Windows-native UI patterns with Fluent UI
- Ensure proper serial port handling and permissions
- Test weight reading accuracy and stability
- Validate all export/import functionality
- Keep offline capability as core requirement