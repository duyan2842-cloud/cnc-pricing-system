-- ============================================================
--  补齐云端 leads 表早期缺失字段
--  背景:远端 leads 表早先手工创建,缺少 length / width / material_factor;
--  20260527000000_create_leads.sql 因表已存在被 Postgres 跳过,
--  导致后续 ALTER 也没补上这几个字段。此 migration 一次性补齐。
--  另外新增 user_id 用于追踪订单提交者 (前端登录后自动写入)。
-- ============================================================

-- 1) 三个尺寸/系数字段:用 numeric,允许 NULL(老数据没值)
alter table public.leads
  add column if not exists length          numeric,
  add column if not exists width           numeric,
  add column if not exists material_factor numeric;

-- 2) user_id - 关联下单客户 (auth.users.id)
--    使用 default auth.uid(),登录用户 INSERT 时自动填入
alter table public.leads
  add column if not exists user_id uuid references auth.users(id) default auth.uid();

-- 3) 索引:按下单人筛选 "我的订单" 时用得到
create index if not exists leads_user_id_idx on public.leads (user_id);

-- 4) 让 PostgREST 立即重新加载 schema 缓存,避免前端继续遇到 "column not found"
notify pgrst, 'reload schema';
