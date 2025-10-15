-- Database initialization script for TiDB
-- This script will run automatically when TiDB starts

-- Create database
CREATE DATABASE IF NOT EXISTS helfy_db;
USE helfy_db;

-- Create a sample users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    status ENUM('active', 'inactive', 'suspended') DEFAULT 'active'
);

-- Create a sample products table
CREATE TABLE IF NOT EXISTS products (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- Create a sample orders table
CREATE TABLE IF NOT EXISTS orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled') DEFAULT 'pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Create a sample order_items table
CREATE TABLE IF NOT EXISTS order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

-- Create default admin user
INSERT IGNORE INTO users (username, email, password_hash, status) VALUES
('admin', 'admin@helfy.com', SHA2('admin123', 256), 'active');

-- Create some sample data for testing CDC
INSERT IGNORE INTO products (name, description, price, stock_quantity) VALUES
('Laptop Pro', 'High-performance laptop for professionals', 1299.99, 50),
('Wireless Mouse', 'Ergonomic wireless mouse', 29.99, 200),
('Mechanical Keyboard', 'RGB mechanical gaming keyboard', 149.99, 75),
('USB-C Hub', 'Multi-port USB-C hub with HDMI', 79.99, 100),
('Monitor 4K', '27-inch 4K UHD monitor', 399.99, 25);

-- Create a sample order
INSERT IGNORE INTO orders (user_id, total_amount, order_status) VALUES
(1, 1329.98, 'pending');

-- Create order items
INSERT IGNORE INTO order_items (order_id, product_id, quantity, price) VALUES
(1, 1, 1, 1299.99),
(1, 2, 1, 29.99);

-- Create a user for the application
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password123';
GRANT ALL PRIVILEGES ON helfy_db.* TO 'app_user'@'%';
FLUSH PRIVILEGES;

-- Show tables created
SHOW TABLES;