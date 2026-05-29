# CNC Pricing Console

> 面向 **3D 打印 / 激光切割 / 五金加工 / 木工定制** 行业的在线算价 + 订单留存系统。
> 前后端分离架构,前端纯静态(零运行时依赖),后端使用 Supabase BaaS。

---

## ✦ 项目简介

一个赛博工业仪表盘风格的报价 + 生产调度系统:客户端做实时报价 + 下单 + 收银,工厂端是独立的 **FACTORY HUB · 生产调度中心**(全屏 60/40 主板,左侧任务调度队列、右侧实时生产看板)。订单经过 `1_待付款 → 2_待派单 → 3_加工中 → 3.5_质检中 → 3.8_已打包 → 4_已发货 → 5_已完成` 七段状态机,前端用 stepper 可视化进度并通过 modal 一键流转。

**主要能力**

| 模块 | 说明 |
| --- | --- |
| 实时报价 | `(长 × 宽 × 高 × 材料系数 × 0.0001) × 数量`,数字滚轮翻页动画 |
| 行业材料库 | 三大分组(塑料 / 金属 / 木材)+ 自定义材料模式 |
| FACTORY HUB | 全屏 60/40 主板:左侧 DISPATCH QUEUE 任务调度,右侧 LIVE BOARD 在制状态流转 + 物料汇总 |
| KPI 看板 | 工厂端顶部三卡:本月接单 / 准时率(72h SLA) / 当前待处理 |
| 进度 stepper | 4 段可视化(开始 / 质检 / 包装 / 出库),点击"更新进度"弹 modal 一键流转 |
| 物料聚合 | 按未发货订单聚合材料件数 + 体积,辅助物料采购 |
| 订单留存 | 写入 `leads` 表,初始 `status = '1_待付款'`,带尺寸文本快照 |
| Auth 路由守卫 | 未登录强制拦截至登录卡,刷新页面不丢失会话;支持邮箱验证 + 重发链接 |
| Toast 通知 | 赛博朋克风滑入提示,统一处理成功 / 失败 / 网络断线 |
| 安全头 | Vercel 层注入 `X-Frame-Options` / `X-Content-Type-Options` 等 |

---

## ✦ 技术栈

### 前端
- **原生 HTML / CSS / JavaScript** — 零运行时依赖,直接由浏览器加载
- **Tailwind CSS** — 通过 CDN `@tailwindcss/cdn` 引入,用于排版工具类
- **Supabase JS SDK** — `@supabase/supabase-js@2`,通过 CDN 引入

### 后端 (BaaS)
- **Supabase** — Postgres + Auth + Storage(未来) + Row Level Security
- 通过 RLS 策略实现:仅 `authenticated` 角色可读写 `leads` 表

### 部署 & 工具
- **Vercel** — 静态托管 + 环境变量注入(`scripts/build-config.js`)
- **Supabase CLI**(可选)— 用于本地应用 migrations

---

## ✦ 目录结构

```
我的项目/
├── index.html                 # 主控制台:报价 + 提交 + Auth 守卫
├── checkout.html              # 订单收银台:定金 20% + 模拟支付
├── factory.html               # FACTORY HUB:生产调度中心(全屏 60/40 主板)
├── success.html               # 成功页(支持 ?paid=1 切换文案)
├── config.js                  # ⚠ 含密钥,gitignored,本地手填 / Vercel 自动生成
├── config.example.js          # 配置模板
├── .env.example               # 环境变量模板(给 Vercel 用)
├── .gitignore                 # 忽略 config.js / .env / node_modules
├── vercel.json                # Vercel 构建 + 安全头配置
├── scripts/
│   └── build-config.js        # Build 阶段:env → config.js
├── supabase/
│   ├── config.toml            # Supabase CLI 配置
│   └── migrations/            # 数据库版本管理
│       ├── 20260527000000_create_leads.sql
│       ├── 20260528000000_add_height_to_leads.sql
│       ├── 20260528010000_upgrade_leads_to_orders.sql
│       ├── 20260528020000_authenticated_only_policy.sql
│       ├── 20260528030000_business_status_enum.sql
│       ├── 20260529084959_backfill_missing_columns.sql
│       └── 20260529085602_extend_production_status.sql
└── README.md                  # 本文件
```

**前后端分离边界**

- `index.html` / `success.html` / `config.js` / 等是**纯静态前端资产**,部署到 Vercel(或任意 CDN)
- Supabase 提供 Postgres 数据库、Auth 服务、未来的 Storage —— 通过 HTTPS REST/Realtime API 与前端通信
- 二者**没有自有后端服务进程**,数据库的访问控制完全交给 Postgres RLS

---

## ✦ 数据库 Schema (`public.leads`)

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `id` | `bigint identity` | 主键 |
| `created_at` | `timestamptz` | 默认 `now()` |
| `name` | `text` | 客户姓名 |
| `phone` | `text` | 联系电话 |
| `material` | `text` | 选定材料名称 |
| `material_factor` | `numeric` | 材料系数快照 |
| `dimensions` | `text` | 尺寸文本快照,例 `100×50×20 mm · 体积 100,000 mm³` |
| `length` / `width` / `height` | `numeric` | 结构化尺寸,便于报表 |
| `quantity` | `integer` | 数量 |
| `calculated_price` | `numeric` | 算出的预估价 |
| `status` | `text` | 默认 `1_待付款`,带 CHECK 约束限制为 5 态,有索引 |

**RLS 策略**(`20260528020000_authenticated_only_policy.sql` 之后)

- ❌ `anon` 不可访问
- ✅ `authenticated` 可 `INSERT` / `SELECT` / `UPDATE`

---

## ✦ 本地运行指南

### 1. 准备 Supabase 项目

1. 在 [supabase.com](https://supabase.com/) 创建新项目
2. 进入 `Project Settings → API`,记下 `Project URL` 和 `anon public key`
3. 在 `SQL Editor` 中按时间戳顺序执行 `supabase/migrations/` 下所有 `.sql` 文件
   - 或使用 Supabase CLI:`supabase link --project-ref <ref> && supabase db push`
4. 进入 `Authentication → Providers`,确认 Email 已启用;按需开关"Confirm email"

### 2. 配置前端

```bash
# 在项目根目录
cp config.example.js config.js
```

编辑 `config.js`,填入真实凭证:

```js
window.env = {
  SUPABASE_URL:      "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "eyJhbGciOi...",
};
```

> 也可同时 `cp .env.example .env` 留存一份给 Vercel/CI 用。`config.js` 与 `.env` 均已加入 `.gitignore`。

### 3. 启动

由于使用了 ES Module 风格的 Supabase Auth(`detectSessionInUrl` 等)和 fetch,**不能直接双击 `index.html`**(`file://` 协议下部分功能会受限),请用任意静态服务器:

```bash
# 选一:Python
python -m http.server 5173

# 选二:Node 直接来一发 npx
npx serve .

# 选三:VS Code 装个 "Live Server" 扩展,右键 index.html → Open with Live Server
```

打开 `http://localhost:5173`,会看到登录卡 —— 在 Supabase Dashboard 创建一个 user 或直接在登录卡上点「切换至注册」自助注册即可。

---

## ✦ 部署上线 (Vercel)

### 1. 把项目推到 GitHub

```bash
git init
git add .
git commit -m "init: cnc pricing console"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main
```

确认 `.gitignore` 已经把 `config.js` 与 `.env` 排除掉了。

### 2. 在 Vercel 导入项目

1. [vercel.com/new](https://vercel.com/new) → 选刚才推的仓库
2. Framework Preset 选 `Other`(本仓库已带 `vercel.json`,会被自动识别)
3. **Environment Variables** 部分添加两条:
   - `SUPABASE_URL` = `https://YOUR-PROJECT-REF.supabase.co`
   - `SUPABASE_ANON_KEY` = `eyJhbGciOi...`
4. 点 Deploy

构建阶段 `node scripts/build-config.js` 会读取上述环境变量,自动生成 `config.js` 并打包进静态资产。

### 3. 自定义域名 & CORS

- 在 Vercel 项目里配置自定义域名后,**回到 Supabase Dashboard → Authentication → URL Configuration**,把 `Site URL` 和 `Additional Redirect URLs` 加上线上域名,否则邮件确认链接会跳错。

### 4. 上线后的安全检查清单

- [ ] `.gitignore` 真的把 `config.js` 排除了(再 `git ls-files | grep config.js` 确认)
- [ ] Supabase 后台 `leads` 表的 RLS 已启用,且只对 `authenticated` 开放
- [ ] Vercel `Functions / Build Logs` 没有把 anon key 打到日志里
- [ ] 浏览器 DevTools 的 Network 面板能看到 `Authorization: Bearer ...` 头说明会话生效
- [ ] `X-Frame-Options: DENY` 通过 `curl -I https://YOUR-DOMAIN` 验证

---

## ✦ 业务侧操作流(商业闭环)

订单状态机:

```
1_待付款 ─[模拟支付]─▶ 2_待派单 ─[工厂抢单]─▶ 3_加工中 ─[填物流]─▶ 4_已发货 ─[确认收货]─▶ 5_已完成
```

**客户视角 (`index.html` → `checkout.html` → `success.html`)**

1. 访问主页 → 登录卡 → 注册/登录
2. 进入控制台 → 选材料、填尺寸 → 实时报价
3. 填姓名 / 电话,可上传图纸(STEP/DXF/STL,目前仅前端占位)
4. 点「提交订单 · 获取正式报价」→ 写入 `leads`(`status = 1_待付款`)→ 跳转收银台
5. 收银台 (`checkout.html?id=N`):显示订单详情 + 20% 定金 + 模拟支付按钮
6. 点击「模拟支付」→ `status → 2_待派单`,记录 `paid_at` 和 `deposit_amount` → 跳转成功页

**工厂视角 (`factory.html` · FACTORY HUB)**

1. 登录后从主控台顶部主导航点 **`FACTORY HUB · 生产调度中心`** 进入
2. 全屏 60/40 主板:
   - **左 60%** `DISPATCH QUEUE`:每张待派单卡含订单号/材质/尺寸/数量/材质系数 + 工厂结算价(`calculated_price × 0.85`,客户报价小字标注)+ `⚡ 立即抢单` 按钮 + 图纸占位行
   - **右 40%** `LIVE BOARD`:在制订单列表(stepper + `更新进度` 按钮)+ 今日物料需求聚合
3. 顶部 KPI 三卡:本月接单数 / 准时率(≤72h SLA) / 当前待处理(加工 / 质检 / 包装)
4. 「立即抢单」→ `status → 3_加工中`,记录 `factory_user` 和 `accepted_at`,使用条件更新 `.eq("status", "2_待派单")` 防止并发竞抢
5. 「更新进度」→ 弹 modal,4 个选项(加工 / 质检 / 包装 / 出库),点击直接 UPDATE Supabase + 刷新看板;选"出库"自动写 `shipped_at`,卡片立刻从在制列表消失

> **结算口径**:客户端看到的是 `calculated_price`,工厂端只看到 `× 0.85` 的结算价(UI 文案上称"系统已自动计算工厂最优协议价",避免在工厂界面暴露抽成比例)。差额就是平台收入。

**后续状态(待接入)**

- `5_已完成` 需客户确认收货,记 `completed_at`

---

## ✦ 后续 TODO

- [ ] 接入 Supabase Storage,把图纸真正上传到 `leads_blueprints/<order_id>/<file>` 桶
- [ ] 后台订单管理页面 (`admin.html`),按 `status` 过滤、批量改状态
- [ ] 价格公式按行业分流(激光切割按周长、3D 打印按体积、五金按重量)
- [ ] 集成短信 / 邮件通知,新订单实时推送

---

## ✦ License

仅作内部商用,未授权请勿外传。
