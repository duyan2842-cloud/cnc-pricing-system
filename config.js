/* ============================================================
 *  config.js · 硬编码版本
 *  ----------------------------------------------------------
 *  本文件已直接写入 Supabase 公开凭证,无需依赖 Build 阶段
 *  环境变量注入。Cloudflare Pages / Vercel / GitHub Pages /
 *  本地直开均一致可用。
 *
 *  注意:这里使用的是 anon (publishable) public key —
 *  Supabase 设计上允许其出现在浏览器,真正的安全由 Postgres
 *  Row Level Security (RLS) 在数据库层强制执行。
 * ============================================================ */
window.env = {
  SUPABASE_URL:      "https://rjzokjtcbnwenarzqaoe.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJqem9ranRjYm53ZW5hcnpxYW9lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0MDk4OTAsImV4cCI6MjA5Mzk4NTg5MH0.2jyricE4-bXs1WWtUqXIIpGODwNyduVykFAZ80iQyd8",
};
