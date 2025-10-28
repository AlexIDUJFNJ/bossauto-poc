const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const morgan = require('morgan');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3001;

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(morgan('dev'));

// In-memory storage (simula Business Central)
const purchaseOrders = new Map();
const vendors = new Map();
const items = new Map();

// Datos mock iniciales
const initMockData = () => {
  // Vendors
  vendors.set('PROV-001', {
    code: 'PROV-001',
    name: 'Proveedor ABC',
    contact: 'contacto@proveedorabc.com',
    rating: 4.5
  });
  vendors.set('PROV-002', {
    code: 'PROV-002',
    name: 'Industrial Supplies SA',
    contact: 'ventas@industrial.com',
    rating: 4.2
  });
  vendors.set('PROV-003', {
    code: 'PROV-003',
    name: 'Tech Equipment Corp',
    contact: 'sales@techequip.com',
    rating: 4.8
  });

  // Items
  items.set('MAT-001', {
    code: 'MAT-001',
    description: 'Tornillos M10x50mm acero inoxidable',
    unit_price: 1.50,
    stock_quantity: 5000,
    reorder_point: 1000
  });
  items.set('EQU-001', {
    code: 'EQU-001',
    description: 'Compresor industrial 150HP',
    unit_price: 12000.00,
    stock_quantity: 0,
    reorder_point: 1
  });
};

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'BossAuto Mock BC API',
    timestamp: new Date().toISOString(),
    endpoints: {
      vendors: '/api/v1/vendors',
      items: '/api/v1/items',
      purchase_orders: '/api/v1/purchase-orders'
    }
  });
});

// ============================================
// VENDORS ENDPOINTS
// ============================================

// Get all vendors
app.get('/api/v1/vendors', (req, res) => {
  const vendorList = Array.from(vendors.values());
  res.json({
    value: vendorList,
    count: vendorList.length
  });
});

// Get vendor by code
app.get('/api/v1/vendors/:code', (req, res) => {
  const vendor = vendors.get(req.params.code);
  if (!vendor) {
    return res.status(404).json({
      error: 'Vendor not found',
      code: req.params.code
    });
  }
  res.json(vendor);
});

// ============================================
// ITEMS ENDPOINTS
// ============================================

// Get all items
app.get('/api/v1/items', (req, res) => {
  const itemList = Array.from(items.values());
  res.json({
    value: itemList,
    count: itemList.length
  });
});

// Get item by code
app.get('/api/v1/items/:code', (req, res) => {
  const item = items.get(req.params.code);
  if (!item) {
    return res.status(404).json({
      error: 'Item not found',
      code: req.params.code
    });
  }
  res.json(item);
});

// ============================================
// PURCHASE ORDERS ENDPOINTS
// ============================================

// Create Purchase Order
app.post('/api/v1/purchase-orders', (req, res) => {
  try {
    const {
      purchase_request_id,
      vendor_code,
      items: orderItems,
      total_amount,
      requested_by,
      delivery_date
    } = req.body;

    // Validación básica
    if (!purchase_request_id || !vendor_code || !orderItems || !total_amount) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['purchase_request_id', 'vendor_code', 'items', 'total_amount']
      });
    }

    // Simular validación de vendor
    const vendor = vendors.get(vendor_code);
    if (!vendor) {
      return res.status(404).json({
        error: 'Vendor not found in Business Central',
        vendor_code
      });
    }

    // Crear Purchase Order
    const poNumber = `PO-${new Date().getFullYear()}-${String(purchaseOrders.size + 1).padStart(4, '0')}`;
    const documentId = uuidv4();

    const purchaseOrder = {
      document_id: documentId,
      po_number: poNumber,
      purchase_request_id,
      vendor: {
        code: vendor_code,
        name: vendor.name
      },
      items: orderItems,
      total_amount,
      currency: 'USD',
      status: 'pending',
      requested_by,
      delivery_date,
      created_at: new Date().toISOString(),
      bc_status: 'created'
    };

    purchaseOrders.set(poNumber, purchaseOrder);

    // Simular latencia de BC (100-300ms)
    const latency = Math.floor(Math.random() * 200) + 100;
    setTimeout(() => {
      res.status(201).json({
        success: true,
        data: purchaseOrder,
        message: 'Purchase Order created successfully in Business Central'
      });
    }, latency);

  } catch (error) {
    console.error('Error creating PO:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: error.message
    });
  }
});

// Get all Purchase Orders
app.get('/api/v1/purchase-orders', (req, res) => {
  const { status, vendor_code } = req.query;
  let poList = Array.from(purchaseOrders.values());

  // Filtros opcionales
  if (status) {
    poList = poList.filter(po => po.status === status);
  }
  if (vendor_code) {
    poList = poList.filter(po => po.vendor.code === vendor_code);
  }

  res.json({
    value: poList,
    count: poList.length
  });
});

// Get Purchase Order by number
app.get('/api/v1/purchase-orders/:po_number', (req, res) => {
  const po = purchaseOrders.get(req.params.po_number);
  if (!po) {
    return res.status(404).json({
      error: 'Purchase Order not found',
      po_number: req.params.po_number
    });
  }
  res.json(po);
});

// Update Purchase Order status
app.patch('/api/v1/purchase-orders/:po_number', (req, res) => {
  const po = purchaseOrders.get(req.params.po_number);
  if (!po) {
    return res.status(404).json({
      error: 'Purchase Order not found',
      po_number: req.params.po_number
    });
  }

  const { status, notes } = req.body;
  po.status = status || po.status;
  po.notes = notes || po.notes;
  po.updated_at = new Date().toISOString();

  purchaseOrders.set(req.params.po_number, po);

  res.json({
    success: true,
    data: po,
    message: 'Purchase Order updated successfully'
  });
});

// ============================================
// ERROR HANDLING
// ============================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    path: req.path,
    method: req.method
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Server error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message
  });
});

// ============================================
// START SERVER
// ============================================

initMockData();

app.listen(PORT, () => {
  console.log(`\n🚀 BossAuto Mock BC API running on port ${PORT}`);
  console.log(`📋 Health check: http://localhost:${PORT}/health`);
  console.log(`📊 Vendors: ${vendors.size} loaded`);
  console.log(`📦 Items: ${items.size} loaded`);
  console.log(`\n✅ Ready to accept requests!\n`);
});
