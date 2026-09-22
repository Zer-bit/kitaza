/// The local schema mirrors the server's, with two deliberate differences:
/// money is stored as integer centavos to keep arithmetic exact, and a
/// `sync_queue` table records what still has to reach the cloud.
abstract final class SchemaStatements {
  static const List<String> createTables = [
    '''
    CREATE TABLE owners (
      id         TEXT PRIMARY KEY,
      full_name  TEXT NOT NULL,
      email      TEXT
    )
    ''',
    '''
    CREATE TABLE stores (
      id            TEXT PRIMARY KEY,
      name          TEXT NOT NULL,
      business_type TEXT NOT NULL DEFAULT 'sari_sari',
      currency_code TEXT NOT NULL DEFAULT 'PHP'
    )
    ''',
    '''
    CREATE TABLE products (
      id             TEXT PRIMARY KEY,
      store_id       TEXT NOT NULL,
      name           TEXT NOT NULL,
      barcode        TEXT,
      unit_label     TEXT NOT NULL DEFAULT 'pc',
      cost_price     INTEGER NOT NULL DEFAULT 0,
      selling_price  INTEGER NOT NULL DEFAULT 0,
      stock_quantity REAL NOT NULL DEFAULT 0,
      reorder_level  REAL NOT NULL DEFAULT 0,
      is_active      INTEGER NOT NULL DEFAULT 1,
      updated_at     TEXT NOT NULL,
      deleted_at     TEXT
    )
    ''',
    '''
    CREATE TABLE sales (
      id              TEXT PRIMARY KEY,
      store_id        TEXT NOT NULL,
      payment_method  TEXT NOT NULL DEFAULT 'cash',
      total_amount    INTEGER NOT NULL DEFAULT 0,
      cost_amount     INTEGER NOT NULL DEFAULT 0,
      discount_amount INTEGER NOT NULL DEFAULT 0,
      note            TEXT,
      occurred_at     TEXT NOT NULL,
      updated_at      TEXT NOT NULL,
      deleted_at      TEXT
    )
    ''',
    '''
    CREATE TABLE sale_items (
      id           TEXT PRIMARY KEY,
      sale_id      TEXT NOT NULL,
      product_id   TEXT,
      product_name TEXT NOT NULL,
      quantity     REAL NOT NULL,
      unit_price   INTEGER NOT NULL,
      unit_cost    INTEGER NOT NULL DEFAULT 0,
      line_total   INTEGER NOT NULL,
      FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE
    )
    ''',
    '''
    CREATE TABLE expenses (
      id          TEXT PRIMARY KEY,
      store_id    TEXT NOT NULL,
      category    TEXT NOT NULL,
      description TEXT,
      amount      INTEGER NOT NULL,
      occurred_at TEXT NOT NULL,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    )
    ''',
    '''
    CREATE TABLE owner_withdrawals (
      id          TEXT PRIMARY KEY,
      store_id    TEXT NOT NULL,
      amount      INTEGER NOT NULL,
      reason      TEXT,
      occurred_at TEXT NOT NULL,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    )
    ''',
    '''
    CREATE TABLE stock_movements (
      id          TEXT PRIMARY KEY,
      store_id    TEXT NOT NULL,
      product_id  TEXT NOT NULL,
      movement    TEXT NOT NULL,
      quantity    REAL NOT NULL,
      unit_cost   INTEGER NOT NULL DEFAULT 0,
      note        TEXT,
      occurred_at TEXT NOT NULL,
      updated_at  TEXT NOT NULL,
      deleted_at  TEXT
    )
    ''',
    '''
    CREATE TABLE sync_queue (
      id         INTEGER PRIMARY KEY AUTOINCREMENT,
      entity     TEXT NOT NULL,
      entity_id  TEXT NOT NULL,
      payload    TEXT NOT NULL,
      created_at TEXT NOT NULL,
      attempts   INTEGER NOT NULL DEFAULT 0,
      last_error TEXT
    )
    ''',
  ];

  /// Every index here backs a query the app runs on a user-visible path.
  static const List<String> createIndexes = [
    'CREATE INDEX products_store_name_idx ON products (store_id, name)',
    'CREATE INDEX products_low_stock_idx ON products (store_id, reorder_level, stock_quantity)',
    'CREATE INDEX sales_store_occurred_idx ON sales (store_id, occurred_at DESC)',
    'CREATE INDEX sale_items_sale_idx ON sale_items (sale_id)',
    'CREATE INDEX expenses_store_occurred_idx ON expenses (store_id, occurred_at DESC)',
    'CREATE INDEX withdrawals_store_occurred_idx ON owner_withdrawals (store_id, occurred_at DESC)',
    'CREATE INDEX stock_movements_product_idx ON stock_movements (product_id, occurred_at DESC)',
    'CREATE UNIQUE INDEX sync_queue_entity_idx ON sync_queue (entity, entity_id)',
  ];
}
