-- Whether a store's figures may be pooled into the anonymous comparisons
-- other owners see. Only medians across at least twenty stores are ever
-- published, and an owner can turn this off in Settings.
ALTER TABLE stores
    ADD COLUMN share_benchmarks BOOLEAN NOT NULL DEFAULT TRUE;
