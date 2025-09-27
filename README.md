# Flutter Truck Weighing System - Comprehensive Project Specification

## Project Overview
Build a desktop Flutter application for managing truck loading/unloading operations with real-time weight measurement from COM4 serial devices. The system should work as a weighbridge management solution with full offline capabilities and Odoo ERP integration.

## Core Functionality Requirements

### 1. Weight Reading System
- **Serial Communication**: Read weight data continuously from COM4 port
- **Weight Processing**: Parse incoming data to extract weight in kilograms
- **Real-time Updates**: Display live weight readings with automatic refresh
- **Calibration Support**: Allow zero/tare weight calibration
- **Stability Detection**: Implement weight stability algorithms to determine when to capture final readings
- **Error Handling**: Robust error handling for serial connection issues

### 2. Database Schema (SQLite with sqflite)

#### Clients Table
```sql
CREATE TABLE clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  mobile TEXT,
  street TEXT,
  street2 TEXT,
  city TEXT,
  state_id INTEGER,
  zip TEXT,
  country_id INTEGER,
  vat TEXT,
  is_company BOOLEAN DEFAULT false,
  supplier_rank INTEGER DEFAULT 0,
  customer_rank INTEGER DEFAULT 1,
  category_ids TEXT, -- JSON array of category IDs
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  write_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT true,
  odoo_id INTEGER, -- For syncing with Odoo
  sync_status INTEGER DEFAULT 0 -- 0: pending, 1: synced, 2: error
);
```

#### Suppliers Table
```sql
CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  mobile TEXT,
  street TEXT,
  street2 TEXT,
  city TEXT,
  state_id INTEGER,
  zip TEXT,
  country_id INTEGER,
  vat TEXT,
  is_company BOOLEAN DEFAULT true,
  supplier_rank INTEGER DEFAULT 1,
  customer_rank INTEGER DEFAULT 0,
  category_ids TEXT,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  write_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  active BOOLEAN DEFAULT true,
  odoo_id INTEGER,
  sync_status INTEGER DEFAULT 0
);
```

#### Materials Table
```sql
CREATE TABLE materials (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  default_code TEXT, -- Internal reference
  barcode TEXT,
  list_price REAL DEFAULT 0.0,
  standard_price REAL DEFAULT 0.0,
  uom_id INTEGER, -- Unit of measure
  uom_po_id INTEGER, -- Purchase unit of measure
  categ_id INTEGER, -- Product category
  type TEXT DEFAULT 'product', -- product, consu, service
  tracking TEXT DEFAULT 'none', -- none, lot, serial
  description TEXT,
  active BOOLEAN DEFAULT true,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  write_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  odoo_id INTEGER,
  sync_status INTEGER DEFAULT 0
);
```

#### Orders Table
```sql
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  order_number TEXT NOT NULL UNIQUE,
  client_id INTEGER,
  supplier_id INTEGER,
  material_id INTEGER,
  operation_type TEXT NOT NULL, -- 'loading' or 'unloading'
  truck_plate TEXT NOT NULL,
  driver_name TEXT,
  driver_license TEXT,
  gross_weight REAL DEFAULT 0.0,
  tare_weight REAL DEFAULT 0.0,
  net_weight REAL DEFAULT 0.0,
  unit_price REAL DEFAULT 0.0,
  total_amount REAL DEFAULT 0.0,
  status TEXT DEFAULT 'active', -- active, completed, cancelled
  weigh_in_time DATETIME,
  weigh_out_time DATETIME,
  notes TEXT,
  create_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  write_date DATETIME DEFAULT CURRENT_TIMESTAMP,
  odoo_id INTEGER,
  sync_status INTEGER DEFAULT 0,
  invoice_printed BOOLEAN DEFAULT false,
  FOREIGN KEY (client_id) REFERENCES clients (id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers (id),
  FOREIGN KEY (material_id) REFERENCES materials (id)
);
```

#### Sync Queue Table
```sql
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id INTEGER NOT NULL,
  operation TEXT NOT NULL, -- 'create', 'update', 'delete'
  data TEXT, -- JSON data
  attempts INTEGER DEFAULT 0,
  max_attempts INTEGER DEFAULT 3,
  last_attempt DATETIME,
  error_message TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 3. Odoo Integration
- **REST API Client**: Implement Odoo XML-RPC or REST API client
- **Authentication**: Handle Odoo login with database, username, password
- **Model Mapping**: Map local tables to Odoo models (res.partner, product.product, etc.)
- **Bidirectional Sync**: Support both upload and download synchronization
- **Conflict Resolution**: Handle sync conflicts with timestamp-based resolution
- **Batch Operations**: Efficient bulk sync operations

### 4. Offline Mode & Synchronization
- **Connection Monitoring**: Continuously monitor server connectivity
- **Queue System**: Queue all operations when offline
- **Auto-sync**: Automatically sync when connection is restored
- **Retry Logic**: Implement exponential backoff for failed sync attempts
- **Data Integrity**: Ensure data consistency during sync operations
- **Progress Indicators**: Show sync progress and status

### 5. Multi-Order Management
- **Active Orders List**: Display all active orders in a dashboard
- **Order States**: Track orders through different states (weighing in, loaded/unloaded, weighing out)
- **Quick Search**: Search orders by truck plate, driver name, or order number
- **Order Templates**: Create order templates for frequent operations
- **Bulk Operations**: Support bulk status updates and operations

### 6. Printing System
- **Invoice Generation**: Generate professional invoices with company branding
- **Weighing Tickets**: Print weighing tickets with all relevant information
- **Template Engine**: Use customizable templates for different document types
- **Print Preview**: Show print preview before printing
- **Multiple Printers**: Support multiple printer configurations
- **PDF Export**: Export documents as PDF files

## Technical Implementation Requirements

### 1. State Management (Provider)
```dart
// Example provider structure
class WeightProvider extends ChangeNotifier {
  double currentWeight = 0.0;
  bool isStable = false;
  bool isConnected = false;
  // Weight reading logic
}

class OrderProvider extends ChangeNotifier {
  List<Order> activeOrders = [];
  Order? selectedOrder;
  // Order management logic
}

class SyncProvider extends ChangeNotifier {
  bool isOnline = false;
  int pendingSyncCount = 0;
  // Sync management logic
}
```

### 2. COM Port Communication (FFI Implementation)
```dart
// If no Dart package available, use FFI with Windows DLL
class SerialCommunication {
  late final DynamicLibrary _lib;
  late final int Function() _openPort;
  late final int Function() _readWeight;
  late final void Function() _closePort;
  
  bool initialize() {
    _lib = DynamicLibrary.open('serial_comm.dll');
    // Bind functions
  }
}
```

### 3. Required Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.5
  fluent_ui: latest
  sqflite_common_ffi: ^2.3.0
  http: ^1.1.0
  dio: ^5.3.2  # For advanced HTTP client
  ffi: ^2.1.0
  win32: ^5.0.9
  printing: ^5.11.0
  intl: ^0.18.1
  connectivity_plus: ^4.0.2
  window_manager: ^0.3.7
  bitsdojo_window: ^0.1.6
  fl_chart: ^0.64.0  # For charts/graphs
  data_table_2: ^2.5.9
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  json_serializable: ^6.7.1
  json_annotation: ^4.8.1
  uuid: ^4.1.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

### 4. Localization Implementation
```dart
// Use flutter_localizations
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.18.1

// Generate localization files for multiple languages
// Support at least: English, Turkish, Arabic
```

## UI/UX Design Requirements

### 1. Modern Design System
- **Material Design 3**: Use fluent UI package  design principles
- **Custom Theme**: Implement industrial/professional color scheme
- **Dark/Light Mode**: Support both themes with system preference detection
- **semi-fixed Layout**: Adapt to minmized window and full window, do not allow the user to change the window freely
- **Typography**: Use clear, readable fonts suitable for industrial environment

### 2. Main Dashboard Layout
```
┌─────────────────────────────────────────────────────────────────┐
│ Header: Logo | Current Weight Display | Connection Status | Menu │
├─────────────────┬───────────────────────────────────────────────┤
│ Quick Actions   │ Active Orders Table                           │
│ - New Order     │ - Order Number | Truck | Material | Status    │
│ - Client Mgmt   │ - Net Weight | Driver | Time | Actions        │
│ - Material Mgmt │                                               │
│ - Reports       │                                               │
│ - Settings      │                                               │
├─────────────────┼───────────────────────────────────────────────┤
│ Weight Display  │ Selected Order Details                        │
│ Current: XXX kg │ - Client/Supplier Info                        │
│ Status: Stable  │ - Material Details                           │
│ [Capture]       │ - Weight History                             │
└─────────────────┴───────────────────────────────────────────────┘
```

### 3. Subtle Animations
- **Page Transitions**: Smooth slide transitions between screens
- **Loading States**: Elegant loading spinners and progress indicators
- **Weight Updates**: Smooth number animations for weight changes
- **List Updates**: Gentle fade/slide animations for list item changes
- **Status Changes**: Color transition animations for status updates
- **Micro-interactions**: Button hover effects, form field focus animations

### 4. Key Screens Design

#### Weight Reading Screen
- Large, prominent weight display with color coding (red: unstable, green: stable)
- Real-time graph showing weight history
- Quick action buttons for tare, capture, calibrate
- Current order information panel

#### Order Management Screen
- Searchable and filterable data table
- Quick filters (Active, Completed, Today, This Week)
- Batch action capabilities
- Export functionality

#### Client/Supplier Management
- CRUD operations with validation
- Import/Export capabilities
- Duplicate detection
- Sync status indicators

### 5. Error Handling & User Feedback
- **Toast Messages**: For quick success/error feedback
- **Dialog Boxes**: For important confirmations and detailed errors
- **Loading States**: Clear indication of background operations
- **Offline Indicators**: Visual indicators when system is offline
- **Validation**: Real-time form validation with helpful error messages

## Advanced Features

### 1. Reporting & Analytics
- Daily/weekly/monthly weight reports
- Client/supplier performance analytics
- Material flow analysis
- Revenue tracking and projections
- Export to Excel/PDF capabilities

### 2. Security & Access Control
- User authentication system
- Role-based permissions
- Audit trail for all operations
- Data encryption for sensitive information
- Backup and restore capabilities

### 3. Integration Capabilities
- Weighbridge integration protocols
- Barcode/QR code scanning for quick data entry
- Camera integration for truck/driver photo capture
- Email notification system
- SMS integration for alerts

### 4. Performance Optimization
- Database query optimization
- Lazy loading for large datasets
- Memory management for continuous operation
- Background sync processes
- Caching strategies for frequently accessed data

## Deployment & Maintenance

### 1. Windows Desktop Deployment
- Create MSIX installer package
- Include all required DLLs and dependencies
- Auto-update mechanism
- Installation wizard with database setup
- System requirements check

### 2. Configuration Management
- Settings UI for COM port configuration
- Odoo server connection settings
- Printer configuration
- User preferences management
- Backup/restore settings

This specification provides a comprehensive foundation for building a professional truck weighing management system with modern Flutter architecture, robust offline capabilities, and seamless ERP integration.