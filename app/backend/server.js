const express = require("express");
const mysql = require("mysql2");
const cors = require("cors");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// DB connection using environment variables (injected via EC2 user-data or .env)
const db = mysql.createConnection({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME || "ziggydb",
});

db.connect((err) => {
  if (err) {
    console.error("Database connection failed:", err.message);
  } else {
    console.log("Connected to RDS MySQL");
  }
});

// Health check endpoint — used by ALB target group
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok", tier: "application" });
});

// Get all menu items
app.get("/api/menu", (req, res) => {
  const query = "SELECT * FROM menu_items ORDER BY id ASC";
  db.query(query, (err, results) => {
    if (err) {
      console.error("Query error:", err);
      return res.status(500).json({ error: "Database query failed" });
    }
    res.json(results);
  });
});

// Get single menu item
app.get("/api/menu/:id", (req, res) => {
  const { id } = req.params;
  db.query("SELECT * FROM menu_items WHERE id = ?", [id], (err, results) => {
    if (err) return res.status(500).json({ error: "Query failed" });
    if (results.length === 0) return res.status(404).json({ error: "Item not found" });
    res.json(results[0]);
  });
});

// Place an order
app.post("/api/orders", (req, res) => {
  const { customer_name, item_id, quantity } = req.body;
  if (!customer_name || !item_id || !quantity) {
    return res.status(400).json({ error: "Missing required fields" });
  }
  const query = "INSERT INTO orders (customer_name, item_id, quantity) VALUES (?, ?, ?)";
  db.query(query, [customer_name, item_id, quantity], (err, result) => {
    if (err) return res.status(500).json({ error: "Failed to place order" });
    res.status(201).json({ message: "Order placed", orderId: result.insertId });
  });
});

app.listen(PORT, () => {
  console.log(`Ziggy App Server running on port ${PORT}`);
});
