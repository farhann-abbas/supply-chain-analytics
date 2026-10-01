# Supply Chain Inventory & Operations Analytics

## 📌 Project Overview

This project analyzes end-to-end supply chain operations using **PostgreSQL, SQL, Excel, and Power BI**.

The analysis focuses on:

- Inventory management
- Procurement performance
- Order fulfillment
- Inventory turnover
- Supplier performance and risk
- Replenishment planning
- ABC and XYZ inventory classification
- Working capital and inventory efficiency

The project uses raw supply chain transaction data and calculates business metrics dynamically using SQL, Excel formulas, PivotTables, and Power BI measures rather than relying only on pre-calculated analysis tables.

---

## 📊 Project Highlights

| KPI | Result |
|---|---:|
| Products | 150 |
| Sales Orders | 15,000 |
| Purchase Orders | 5,000 |
| Annual Demand | 311,056 units |
| Overall Customer Fill Rate | 90.30% |
| Supplier Fill Rate | 86.32% |
| Inventory Turnover | 9.16x |
| Days Inventory | 39.85 days |
| Current Inventory Value | $92.20K |
| Total Purchase Spend | $22.90M |
| Products Below Reorder Point | 28 |

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
| SQL | Data validation, transformation, analysis and KPI calculation |
| Excel | Inventory analysis, ABC/XYZ analysis, replenishment analysis and reporting |
| Power BI | Executive dashboard and KPI visualization |
| DBeaver | SQL development and query execution |
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
```

## 📊 Power BI Dashboard

The Power BI dashboard provides an executive view of supply chain performance.

### Executive Dashboard Preview

![Supply Chain Executive Dashboard](screenshots/Power%20Bi%20Dashboard.png)

### Executive KPIs

- Total Ordered Quantity
- Total Shipped Quantity
- Overall Fill Rate
- Supplier Fill Rate
- Total Purchase Spend
- Products Below Reorder Point
- Current Inventory Value
- Inventory Turnover
- Days Inventory
- Products With Inventory