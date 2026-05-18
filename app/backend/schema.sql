-- Ziggy Food App - Database Schema
-- Run this on your RDS MySQL instance after provisioning

CREATE DATABASE IF NOT EXISTS ziggydb;
USE ziggydb;

CREATE TABLE IF NOT EXISTS menu_items (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(100)   NOT NULL,
  description VARCHAR(255),
  price       DECIMAL(10, 2) NOT NULL,
  category    VARCHAR(50),
  image_url   VARCHAR(500),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  id            INT AUTO_INCREMENT PRIMARY KEY,
  customer_name VARCHAR(100) NOT NULL,
  item_id       INT          NOT NULL,
  quantity      INT          NOT NULL DEFAULT 1,
  ordered_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (item_id) REFERENCES menu_items(id)
);

-- Seed data
INSERT INTO menu_items (name, description, price, category) VALUES
  ('Pizza',       'Cheesy wood-fired pizza',            299.00, 'Italian'),
  ('Biryani',     'Authentic Hyderabadi biryani',       199.00, 'Indian'),
  ('Burger',      'Juicy double-patty burger',          149.00, 'Fast Food'),
  ('Pasta',       'Creamy white sauce penne',           249.00, 'Italian'),
  ('Special Dish','Chef'\''s daily special',            349.00, 'Special');
