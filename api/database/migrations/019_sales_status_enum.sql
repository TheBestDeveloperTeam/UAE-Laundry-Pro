ALTER TABLE sales_orders
  MODIFY COLUMN status ENUM(
    'draft', 'confirmed', 'received', 'sorting', 'processing', 'quality_check',
    'packed', 'ready', 'ready_for_collection', 'out_for_delivery', 'delivered',
    'on_hold', 'rework_required', 'closed', 'cancelled'
  ) NOT NULL DEFAULT 'draft';
