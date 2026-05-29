-- ============================================================
--  订单状态枚举升级为商业流闭环:
--    1_待付款 → 2_待派单 → 3_加工中 → 4_已发货 → 5_已完成
--  同时新增定金、抢单工厂、物流单号等流转字段
-- ============================================================

-- 1) 把旧状态值迁移到新枚举
update public.leads
set status = '1_待付款'
where status in ('待跟进', '');

-- 2) 默认状态改为「1_待付款」,新订单进入收银台流程
alter table public.leads
  alter column status set default '1_待付款';

-- 3) 用 CHECK 约束锁住允许的状态集合
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'leads_status_check' and conrelid = 'public.leads'::regclass
  ) then
    alter table public.leads drop constraint leads_status_check;
  end if;
end$$;

alter table public.leads
  add constraint leads_status_check
  check (status in ('1_待付款', '2_待派单', '3_加工中', '4_已发货', '5_已完成'));

-- 4) 新增商业流字段
alter table public.leads
  add column if not exists deposit_amount numeric,
  add column if not exists paid_at        timestamptz,
  add column if not exists factory_user   uuid references auth.users(id),
  add column if not exists accepted_at    timestamptz,
  add column if not exists tracking_no    text,
  add column if not exists shipped_at     timestamptz,
  add column if not exists completed_at   timestamptz;

-- 5) 抢单查询常用索引
create index if not exists leads_factory_user_idx on public.leads (factory_user);

-- 6) 让 authenticated 角色能 UPDATE 自己关心的字段
--    (之前的策略已经允许 authenticated update,这里仅做确认/重建)
drop policy if exists "authenticated can update leads" on public.leads;
create policy "authenticated can update leads"
  on public.leads
  for update
  to authenticated
  using (true)
  with check (true);
