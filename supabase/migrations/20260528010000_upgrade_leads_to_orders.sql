-- ============================================================
--  leads 表升级为订单留存表
--  目标字段:id, created_at, name, phone, material, dimensions,
--           quantity, calculated_price, status
--  保留原有结构化字段 (length / width / height / material_factor)
--  以便后续报表与筛选,均为兼容性增量,不丢数据。
-- ============================================================

-- 1) 价格列改名:price → calculated_price
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='leads' and column_name='price'
  ) and not exists (
    select 1 from information_schema.columns
    where table_schema='public' and table_name='leads' and column_name='calculated_price'
  ) then
    alter table public.leads rename column price to calculated_price;
  end if;
end$$;

-- 2) 新增 dimensions (尺寸文本快照,形如 "100×50×20mm · 100000mm³")
alter table public.leads
  add column if not exists dimensions text;

-- 3) 新增 status (订单状态),默认 '待跟进'
alter table public.leads
  add column if not exists status text not null default '待跟进';

-- 4) 为状态字段建索引,后续按状态分拣订单更快
create index if not exists leads_status_idx on public.leads (status);

-- 5) 为创建时间建倒序索引,后台列表按最新订单排序
create index if not exists leads_created_at_idx on public.leads (created_at desc);
