return {
  postgres = {
    up = [[
      CREATE OR REPLACE FUNCTION batch_delete_expired_rows() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
        BEGIN
          IF RANDOM() < 0.01 THEN
            EXECUTE FORMAT('WITH rows AS (SELECT ctid FROM %s WHERE ttl < CURRENT_TIMESTAMP AT TIME ZONE ''UTC'' ORDER BY ttl LIMIT 50000 FOR UPDATE SKIP LOCKED) DELETE FROM %s WHERE ctid IN (TABLE rows)', TG_TABLE_NAME, TG_TABLE_NAME);
          END IF;
          RETURN NULL;
        END;
      $$;
    ]],
  },
  cassandra = {
    up = [[]],
  }
}
