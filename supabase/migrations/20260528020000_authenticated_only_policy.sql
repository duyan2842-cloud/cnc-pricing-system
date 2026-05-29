-- ============================================================
--  收紧 RLS 策略:仅登录态可写入、查看 leads
--  前端通过 Supabase Auth 登录后,Supabase JS SDK 会自动把 JWT
--  附加到请求头,使其身份从 anon 切换为 authenticated。
-- ============================================================

-- 1) 删除旧的匿名写入策略(若存在)
drop policy if exists "anon can insert leads" on public.leads;

-- 2) 仅允许登录用户写入订单线索
create policy "authenticated can insert leads"
  on public.leads
  for insert
  to authenticated
  with check (true);

-- 3) 允许登录用户读取订单线索 (后台报表 / 跟进列表用)
create policy "authenticated can select leads"
  on public.leads
  for select
  to authenticated
  using (true);

-- 4) 允许登录用户更新订单状态 (status / 跟进备注)
create policy "authenticated can update leads"
  on public.leads
  for update
  to authenticated
  using (true)
  with check (true);
