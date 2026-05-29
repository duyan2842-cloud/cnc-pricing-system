-- ============================================================
--  扩展生产流转状态:
--    在 3_加工中 与 4_已发货 之间插入 3.5_质检中 / 3.8_已打包
--  数字前缀保留字典序: '3' < '3.5' < '3.8' < '4'
-- ============================================================

-- 1) 替换 CHECK 约束以接纳新值
alter table public.leads drop constraint if exists leads_status_check;

alter table public.leads
  add constraint leads_status_check
  check (status in (
    '1_待付款',
    '2_待派单',
    '3_加工中',
    '3.5_质检中',
    '3.8_已打包',
    '4_已发货',
    '5_已完成'
  ));

-- 2) 通知 PostgREST 重载 schema 缓存
notify pgrst, 'reload schema';
