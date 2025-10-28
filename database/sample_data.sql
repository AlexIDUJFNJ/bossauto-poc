-- BossAuto PoC - Sample Data
-- Datos de prueba para demostración

-- Sample Purchase Requests
INSERT INTO purchase_requests (
    request_id, requester_name, requester_department, requester_email,
    total_amount, currency, supplier_name, supplier_code,
    status, approval_level, approver_name, sla_deadline,
    requested_date, delivery_date, bc_integration_status
) VALUES
-- Auto-aprobación (< $1,000)
('PR-2025-001', 'Juan Pérez', 'Producción', 'juan.perez@company.com',
 750.00, 'USD', 'Proveedor ABC', 'PROV-001',
 'approved', 'auto', 'Auto-aprobación', CURRENT_TIMESTAMP,
 CURRENT_TIMESTAMP - INTERVAL '2 days', CURRENT_DATE + INTERVAL '15 days', 'success'),

-- Nivel Manager (pendiente)
('PR-2025-002', 'María García', 'Mantenimiento', 'maria.garcia@company.com',
 3500.00, 'USD', 'Industrial Supplies SA', 'PROV-002',
 'pending_approval', 'manager', 'Gerente Compras', CURRENT_TIMESTAMP + INTERVAL '20 hours',
 CURRENT_TIMESTAMP - INTERVAL '4 hours', CURRENT_DATE + INTERVAL '10 days', 'success'),

-- Nivel Director (pendiente urgente)
('PR-2025-003', 'Carlos Rodríguez', 'Logística', 'carlos.rodriguez@company.com',
 15000.00, 'USD', 'Tech Equipment Corp', 'PROV-003',
 'pending_approval', 'director', 'Director Operaciones', CURRENT_TIMESTAMP + INTERVAL '2 hours',
 CURRENT_TIMESTAMP - INTERVAL '46 hours', CURRENT_DATE + INTERVAL '30 days', 'success'),

-- Nivel CEO (overdue)
('PR-2025-004', 'Ana Martínez', 'Compras', 'ana.martinez@company.com',
 45000.00, 'USD', 'Global Machinery Ltd', 'PROV-004',
 'pending_approval', 'ceo', 'CEO', CURRENT_TIMESTAMP - INTERVAL '5 hours',
 CURRENT_TIMESTAMP - INTERVAL '75 hours', CURRENT_DATE + INTERVAL '60 days', 'success'),

-- Rechazada
('PR-2025-005', 'Pedro Sánchez', 'IT', 'pedro.sanchez@company.com',
 8900.00, 'USD', 'Software Solutions Inc', 'PROV-005',
 'rejected', 'director', 'Director Operaciones', CURRENT_TIMESTAMP - INTERVAL '10 hours',
 CURRENT_TIMESTAMP - INTERVAL '36 hours', CURRENT_DATE + INTERVAL '5 days', 'success');

-- Sample Purchase Request Items
INSERT INTO purchase_request_items (request_id, item_code, description, quantity, unit_price, total) VALUES
('PR-2025-001', 'MAT-001', 'Tornillos M10x50mm acero inoxidable', 500, 1.50, 750.00),

('PR-2025-002', 'MAT-002', 'Rodamientos SKF 6205', 50, 35.00, 1750.00),
('PR-2025-002', 'MAT-003', 'Aceite hidráulico ISO 68 - 20L', 50, 35.00, 1750.00),

('PR-2025-003', 'EQU-001', 'Compresor industrial 150HP', 1, 12000.00, 12000.00),
('PR-2025-003', 'EQU-002', 'Sistema de filtrado aire comprimido', 1, 3000.00, 3000.00),

('PR-2025-004', 'MAC-001', 'Torno CNC industrial', 1, 45000.00, 45000.00),

('PR-2025-005', 'SW-001', 'Licencias software ERP (10 usuarios)', 10, 890.00, 8900.00);

-- Sample Approval History
INSERT INTO approval_history (request_id, approval_level, approver_name, approver_email, action, comments, decision_date, sla_met) VALUES
('PR-2025-001', 'auto', 'Sistema', 'system@company.com', 'approved', 'Auto-aprobado por monto menor a $1,000', CURRENT_TIMESTAMP - INTERVAL '2 days', TRUE),

('PR-2025-002', 'manager', 'Gerente Compras', 'manager@company.com', 'pending', NULL, NULL, NULL),

('PR-2025-003', 'manager', 'Gerente Compras', 'manager@company.com', 'approved', 'Aprobado para siguiente nivel', CURRENT_TIMESTAMP - INTERVAL '40 hours', TRUE),
('PR-2025-003', 'director', 'Director Operaciones', 'director@company.com', 'pending', NULL, NULL, NULL),

('PR-2025-004', 'manager', 'Gerente Compras', 'manager@company.com', 'approved', 'Monto alto, requiere aprobación CEO', CURRENT_TIMESTAMP - INTERVAL '70 hours', TRUE),
('PR-2025-004', 'director', 'Director Operaciones', 'director@company.com', 'approved', 'Inversión crítica, escalado a CEO', CURRENT_TIMESTAMP - INTERVAL '50 hours', TRUE),
('PR-2025-004', 'ceo', 'CEO', 'ceo@company.com', 'pending', NULL, NULL, NULL),

('PR-2025-005', 'manager', 'Gerente Compras', 'manager@company.com', 'approved', 'Budget disponible', CURRENT_TIMESTAMP - INTERVAL '30 hours', TRUE),
('PR-2025-005', 'director', 'Director Operaciones', 'director@company.com', 'rejected', 'No es prioritario para este trimestre', CURRENT_TIMESTAMP - INTERVAL '10 hours', TRUE);

-- Sample Notifications
INSERT INTO notifications (request_id, notification_type, recipient, message, status, sent_at) VALUES
('PR-2025-001', 'telegram', 'juan.perez@company.com', 'Su solicitud PR-2025-001 ha sido auto-aprobada', 'sent', CURRENT_TIMESTAMP - INTERVAL '2 days'),

('PR-2025-002', 'telegram', 'manager@company.com', 'Nueva solicitud PR-2025-002 requiere su aprobación ($3,500)', 'sent', CURRENT_TIMESTAMP - INTERVAL '4 hours'),
('PR-2025-002', 'email', 'manager@company.com', 'Recordatorio: Solicitud PR-2025-002 pendiente de aprobación', 'sent', CURRENT_TIMESTAMP - INTERVAL '2 hours'),

('PR-2025-003', 'telegram', 'director@company.com', 'URGENTE: Solicitud PR-2025-003 ($15,000) requiere aprobación en 2 horas', 'sent', CURRENT_TIMESTAMP - INTERVAL '1 hour'),

('PR-2025-004', 'telegram', 'ceo@company.com', 'OVERDUE: Solicitud PR-2025-004 ($45,000) excedió SLA', 'sent', CURRENT_TIMESTAMP - INTERVAL '5 hours'),

('PR-2025-005', 'telegram', 'pedro.sanchez@company.com', 'Su solicitud PR-2025-005 ha sido rechazada', 'sent', CURRENT_TIMESTAMP - INTERVAL '10 hours');

-- Sample System Logs
INSERT INTO system_logs (request_id, log_level, component, message, error_details) VALUES
('PR-2025-001', 'INFO', 'webhook', 'Solicitud recibida correctamente', NULL),
('PR-2025-001', 'INFO', 'approval_engine', 'Regla aplicada: auto-aprobación por monto < $1,000', NULL),
('PR-2025-001', 'INFO', 'bc_integration', 'Documento creado en Business Central: BC-2025-001', NULL),
('PR-2025-001', 'INFO', 'notification', 'Notificación Telegram enviada exitosamente', NULL),

('PR-2025-002', 'INFO', 'webhook', 'Solicitud recibida correctamente', NULL),
('PR-2025-002', 'INFO', 'approval_engine', 'Regla aplicada: requiere aprobación de Gerente Compras', NULL),
('PR-2025-002', 'INFO', 'bc_integration', 'Documento creado en Business Central: BC-2025-002', NULL),

('PR-2025-003', 'INFO', 'webhook', 'Solicitud recibida correctamente', NULL),
('PR-2025-003', 'WARNING', 'sla_monitor', 'SLA próximo a vencerse - 2 horas restantes', NULL),

('PR-2025-004', 'INFO', 'webhook', 'Solicitud recibida correctamente', NULL),
('PR-2025-004', 'ERROR', 'sla_monitor', 'SLA excedido por 5 horas', '{"expected": "2025-01-25T10:00:00Z", "actual": "2025-01-25T15:00:00Z"}'),

('PR-2025-005', 'INFO', 'webhook', 'Solicitud recibida correctamente', NULL),
('PR-2025-005', 'INFO', 'approval_engine', 'Solicitud rechazada por Director Operaciones', NULL);

-- Verificar datos insertados
SELECT 'Purchase Requests:', COUNT(*) as total FROM purchase_requests
UNION ALL
SELECT 'Items:', COUNT(*) FROM purchase_request_items
UNION ALL
SELECT 'Approval History:', COUNT(*) FROM approval_history
UNION ALL
SELECT 'Notifications:', COUNT(*) FROM notifications
UNION ALL
SELECT 'System Logs:', COUNT(*) FROM system_logs;
