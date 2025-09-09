# Akhiro Cafe - Point of Sale (POS) System

A modern, clean, and intuitive Point-of-Sale application built with Flutter.

## 🚀 Features

### 📱 Pages Included

#### 1. **Login Page**

- Modern login form with validation
- Demo credentials provided
- Responsive design with gradient background
- Username: `admin`, Password: `password`

#### 2. **Dashboard**

- Sales overview with key metrics
- Interactive sales chart using FL Chart
- Top-selling products display
- Revenue, orders, and items sold summary
- Real-time data visualization

#### 3. **POS (Point of Sale)**

- Product grid with category filtering
- Real-time search functionality
- Shopping cart with quantity management
- Tax calculation (10%)
- Checkout process with order confirmation
- Stock quantity display

#### 4. **Inventory Management**

- Product list with comprehensive details
- Search and filter by category
- Sort by name, price, stock, or category
- Add/Edit/Delete product functionality (placeholders)
- Low stock indicators
- SKU management
- Inventory value calculation

#### 5. **Orders History**

- Complete order history with filtering
- Date range picker for filtering
- Order status management
- Detailed order view with itemized receipts
- Print receipt and refund functionality (placeholders)
- Revenue analytics

#### 6. **Settings**

- Business profile management
- Theme switching (Light/Dark/System)
- POS configuration options
- Data management (sync, export, backup)
- Account management
- Help and support section

## 🏗️ Project Structure

```
lib/
├── src/
│   ├── models/
│   │   ├── product.dart          # Product data model
│   │   ├── cart_item.dart        # Cart item model
│   │   └── order.dart            # Order data model
│   ├── screens/
│   │   ├── login_screen.dart     # Login page
│   │   ├── main_screen.dart      # Main navigation container
│   │   ├── dashboard_screen.dart # Dashboard with analytics
│   │   ├── pos_screen.dart       # Point of sale interface
│   │   ├── inventory_screen.dart # Inventory management
│   │   └── orders_screen.dart    # Orders history
│   ├── settings/
│   │   ├── settings_controller.dart
│   │   ├── settings_service.dart
│   │   └── settings_view.dart    # Enhanced settings page
│   ├── localization/            # Localization files
│   └── app.dart                 # Main app configuration
└── main.dart                    # App entry point
```

## 🎨 Design Features

- **Modern Material Design** with custom coffee shop theme
- **Responsive Layout** optimized for landscape orientation
- **Navigation Rail** for easy horizontal navigation
- **Card-based UI** with consistent spacing and elevation
- **Color-coded Elements** for different status indicators
- **Custom Icons** and intuitive user interface

## 🛠️ Technical Stack

- **Flutter 3.x** with Dart null safety
- **FL Chart** for data visualization
- **Material Design** components
- **Landscape orientation** forced for tablet/desktop use
- **Mock data** for demonstration purposes

## 🚦 Getting Started

### Prerequisites

- Flutter SDK 3.3.0 or higher
- Dart SDK
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:

```bash
git clone <repository-url>
cd akhiro_cafe
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the application:

```bash
flutter run
```

### Demo Login

- **Username:** `admin`
- **Password:** `password`

---

**Built with ❤️ using Flutter**
