-- BossAuto PoC - Database Schema
-- Flujo 1: Motor de Aprobaciones

-- Tabla principal de solicitudes de compra
CREATE TABLE IF NOT EXISTS purchase_requests (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50) UNIQUE NOT NULL,
    requester_name VARCHAR(255) NOT NULL,
    requester_department VARCHAR(255),
    requester_email VARCHAR(255),
    total_amount DECIMAL(15, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'USD',
    supplier_name VARCHAR(255),
    supplier_code VARCHAR(50),
    status VARCHAR(50) NOT NULL,
    approval_level VARCHAR(50),
    approver_name VARCHAR(255),
    sla_deadline TIMESTAMP,
    requested_date TIMESTAMP NOT NULL,
    delivery_date DATE,
    bc_integration_status VARCHAR(50),
    bc_document_id VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de ítems de la solicitud
CREATE TABLE IF NOT EXISTS purchase_request_items (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50) REFERENCES purchase_requests(request_id),
    item_code VARCHAR(100),
    description TEXT,
    quantity DECIMAL(15, 3),
    unit_price DECIMAL(15, 2),
    total DECIMAL(15, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de historial de aprobaciones
CREATE TABLE IF NOT EXISTS approval_history (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50) REFERENCES purchase_requests(request_id),
    approval_level VARCHAR(50),
    approver_name VARCHAR(255),
    approver_email VARCHAR(255),
    action VARCHAR(50), -- 'approved', 'rejected', 'pending'
    comments TEXT,
    decision_date TIMESTAMP,
    sla_met BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de notificaciones enviadas
CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50) REFERENCES purchase_requests(request_id),
    notification_type VARCHAR(50), -- 'telegram', 'email', 'teams'
    recipient VARCHAR(255),
    message TEXT,
    status VARCHAR(50), -- 'sent', 'failed', 'pending'
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de configuración de reglas de aprobación
CREATE TABLE IF NOT EXISTS approval_rules (
    id SERIAL PRIMARY KEY,
    min_amount DECIMAL(15, 2) NOT NULL,
    max_amount DECIMAL(15, 2),
    approval_level VARCHAR(50) NOT NULL,
    approver_role VARCHAR(255) NOT NULL,
    sla_hours INTEGER NOT NULL,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de logs del sistema
CREATE TABLE IF NOT EXISTS system_logs (
    id SERIAL PRIMARY KEY,
    request_id VARCHAR(50),
    log_level VARCHAR(20), -- 'INFO', 'WARNING', 'ERROR'
    component VARCHAR(100), -- 'webhook', 'approval_engine', 'bc_integration', etc.
    message TEXT,
    error_details JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar performance
CREATE INDEX idx_purchase_requests_status ON purchase_requests(status);
CREATE INDEX idx_purchase_requests_request_id ON purchase_requests(request_id);
CREATE INDEX idx_purchase_requests_created_at ON purchase_requests(created_at DESC);
CREATE INDEX idx_approval_history_request_id ON approval_history(request_id);
CREATE INDEX idx_notifications_request_id ON notifications(request_id);
CREATE INDEX idx_system_logs_request_id ON system_logs(request_id);
CREATE INDEX idx_system_logs_created_at ON system_logs(created_at DESC);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para updated_at
CREATE TRIGGER update_purchase_requests_updated_at
    BEFORE UPDATE ON purchase_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insertar reglas de aprobación por defecto
INSERT INTO approval_rules (min_amount, max_amount, approval_level, approver_role, sla_hours) VALUES
(0, 999.99, 'auto', 'Auto-aprobación', 0),
(1000, 4999.99, 'manager', 'Gerente Compras', 24),
(5000, 19999.99, 'director', 'Director Operaciones', 48),
(20000, NULL, 'ceo', 'CEO', 72);

-- Vista para dashboard de solicitudes pendientes
CREATE OR REPLACE VIEW pending_requests_summary AS
SELECT
    pr.request_id,
    pr.requester_name,
    pr.total_amount,
    pr.approval_level,
    pr.approver_name,
    pr.sla_deadline,
    CASE
        WHEN pr.sla_deadline < CURRENT_TIMESTAMP THEN 'OVERDUE'
        WHEN pr.sla_deadline < CURRENT_TIMESTAMP + INTERVAL '4 hours' THEN 'URGENT'
        ELSE 'ON_TIME'
    END as sla_status,
    pr.created_at
FROM purchase_requests pr
WHERE pr.status = 'pending_approval'
ORDER BY pr.sla_deadline ASC;

-- Vista para métricas de aprobación
CREATE OR REPLACE VIEW approval_metrics AS
SELECT
    DATE_TRUNC('day', pr.created_at) as date,
    COUNT(*) as total_requests,
    COUNT(CASE WHEN pr.status = 'approved' THEN 1 END) as approved,
    COUNT(CASE WHEN pr.status = 'rejected' THEN 1 END) as rejected,
    COUNT(CASE WHEN pr.status = 'pending_approval' THEN 1 END) as pending,
    AVG(pr.total_amount) as avg_amount,
    SUM(pr.total_amount) as total_amount
FROM purchase_requests pr
GROUP BY DATE_TRUNC('day', pr.created_at)
ORDER BY date DESC;

-- Comentarios en las tablas
COMMENT ON TABLE purchase_requests IS 'Tabla principal de solicitudes de compra';
COMMENT ON TABLE purchase_request_items IS 'Ítems individuales de cada solicitud';
COMMENT ON TABLE approval_history IS 'Historial completo de decisiones de aprobación';
COMMENT ON TABLE notifications IS 'Log de todas las notificaciones enviadas';
COMMENT ON TABLE approval_rules IS 'Configuración de reglas de aprobación multinivel';
COMMENT ON TABLE system_logs IS 'Logs del sistema para debugging';
