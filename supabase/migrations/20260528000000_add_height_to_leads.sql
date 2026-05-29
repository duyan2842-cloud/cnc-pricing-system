-- ============================================================
--  leads 表追加 height 字段
--  报价公式扩展为 length × width × height × factor × C × qty
-- ============================================================

alter table public.leads
  add column if not exists height numeric not null default 0;
