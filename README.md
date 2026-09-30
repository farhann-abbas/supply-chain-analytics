# Supply Chain Inventory & Operations Analytics

## 📌 Project Overview

This project analyzes end-to-end supply chain operations using **PostgreSQL and SQL**.

The analysis focuses on inventory management, procurement performance, order fulfillment, inventory turnover, supplier risk, and replenishment planning.

The project uses raw supply chain transaction data and calculates business metrics dynamically using SQL rather than relying on pre-calculated analysis tables.

---

## 🎯 Business Objectives

The project addresses key supply chain questions such as:

- How much inventory is currently held?
- Which products require replenishment?
- Which products contribute the most inventory consumption value?
- How are products classified using ABC and XYZ analysis?
- Which suppliers have delivery or replenishment risk?
- What is the overall customer order fulfillment rate?
- Which products are slow-moving?
- How efficiently is inventory being utilized?
- How concentrated is procurement spending across suppliers?
- What are the key supply chain KPIs for management?

---

## 🗂️ Dataset

The project contains seven raw CSV datasets:

- Products
- Suppliers
- Warehouses
- Customers
- Inventory
- Sales Orders
- Purchase Orders

The dataset represents an FMCG-style supply chain environment covering products, suppliers, warehouses, customers, inventory movements, sales transactions, and procurement transactions.

> **Note:** The dataset is a synthetic portfolio dataset created for analytical and demonstration purposes.

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|---|---|
| PostgreSQL | Database management and SQL analysis |
| DBeaver | SQL development and query execution |
| SQL | Data validation, transformation, analysis and KPI calculation |
| VS Code | SQL script organization and project development |
| Git / GitHub | Version control and portfolio presentation |

---

## 🗄️ Database Structure

The PostgreSQL database uses the `scm` schema.

### Core Tables

```text
products
suppliers
warehouses
customers
inventory
sales_orders
purchase_orders