# 公文校对

一个基于 **Rails 8 + Tailwind + Hotwire/Stimulus + Quill** 的公文校对应用：
上传 `.doc/.docx/.pdf/.txt/.md` → 服务端抽取正文 → 富文本编辑（Quill） → 一键 **AI 分析** → 左侧列表 & 右侧高亮联动，支持【忽略】【替换】【定位】。

---

## ✨ 功能概览

* **文件上传**：Active Storage，支持 `.doc/.docx/.pdf/.txt/.md`
* **正文抽取**：`doc_ripper`（依赖 `poppler-utils`、`antiword`）
* **富文本编辑**：Quill 2（CDN 引入，带 Snow 工具栏）
* **AI 校对联动**：

  * 左侧问题列表（消息/建议/严重级）
  * 右侧正文高亮（可定位）
  * 列表项 【忽略】/【替换】实时作用于正文
* **零构建前端**：Importmap + Tailwind（`tailwindcss-rails`）

---

## 🧱 技术栈

* Rails 8（Ruby 3.x）
* PostgreSQL（Docker 本机运行）
* Tailwind CSS（`tailwindcss-rails`）
* Hotwire / Stimulus（前端控制器）
* Quill 2（CDN）
* Active Storage（文件上传）
* `doc_ripper`（文档抽取文本）

---

## ✅ 环境准备

> 以下命令在 **WSL Ubuntu 22** 或类 Linux 环境中执行。

### 1) 系统依赖

```bash
sudo apt update
sudo apt install -y build-essential libpq-dev poppler-utils antiword
```

### 2) PostgreSQL（Docker）

```bash
docker run -d --name pg16 \
  -e POSTGRES_USER=rails \
  -e POSTGRES_PASSWORD=rails \
  -e POSTGRES_DB=rails_dev \
  -p 5432:5432 \
  -v pg16-data:/var/lib/postgresql/data \
  postgres:16
```

### 3) 项目依赖（Gem）

确保 `Gemfile` 含：

```ruby
gem "doc_ripper", "~> 0.0.9"
gem "tailwindcss-rails"
```

安装：

```bash
bundle install
```

---

## ⚙️ 配置

### 1) 数据库（`config/database.yml`）

```yml
default: &default
  adapter: postgresql
  encoding: unicode
  host: 127.0.0.1
  port: 5432
  username: rails
  password: rails
  pool: 5

development:
  <<: *default
  database: rails_dev

test:
  <<: *default
  database: rails_test
```

### 2) Active Storage

```bash
bin/rails active_storage:install
bin/rails db:migrate
```

### 3) Tailwind

```bash
bin/rails tailwindcss:install
# 一次构建（或开发期间用 watch）
bin/rails tailwindcss:build
# bin/rails tailwindcss:watch
```

> 确认：`app/assets/stylesheets/application.tailwind.css` 和 `app/assets/builds/tailwind.css` 存在。
> 若 404：在 `config/initializers/assets.rb` 添加
> `Rails.application.config.assets.paths << Rails.root.join("app/assets/builds")`

### 4) Quill 2（在布局里引入）

`app/views/layouts/application.html.erb` 的 `<head>` 添加：

```erb
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/quill@2/dist/quill.snow.css">
<script src="https://cdn.jsdelivr.net/npm/quill@2/dist/quill.js"></script>
```

---

## 🚀 快速启动

```bash
# 1. 创建数据库
bin/rails db:create

# 2. 构建 Tailwind（或开 watch）
bin/rails tailwindcss:build

# 3. 启动服务器
bin/rails s
# 访问 http://localhost:3000
```
---

## 🛠️ 开发指令速查

```bash
# 启动服务器
bin/rails s

# Tailwind 单次构建 / 监听
bin/rails tailwindcss:build
bin/rails tailwindcss:watch

# 数据库
bin/rails db:create db:migrate
bin/rails db:drop
```

---

## 🔐 安全/注意事项

* 上传大小限制：示例按 15MB 校验，视需要调整。
* PDF/Office 解析：`doc_ripper` 调用系统工具解析纯文本，对复杂版式可能丢失布局，这正适合“语法/用词”级别的 AI 校对。
* 用户隐私：对接外部 AI 时，请在服务端进行调用，避免将文档内容暴露到前端。

---

## 🧪 自测路线

1. 启动 Postgres 容器 → `bin/rails db:create`
2. `bin/rails tailwindcss:build` → `bin/rails s`
3. 访问首页上传 `.docx/.pdf/.txt`
4. 跳转到校对页，点 **AI 分析**
5. 验证列表/高亮/忽略/替换/定位

---

## 🐞 常见问题

* **页面无样式**：确认已执行 `tailwindcss:build`，布局里有 `<%= stylesheet_link_tag "tailwind" %>`，并在 `assets.rb` 添加了 `app/assets/builds`。
* **Stimulus 控制器 404**：确认 `config/importmap.rb` 有
  `pin_all_from "app/javascript/controllers", under: "controllers"`，并重启服务器。
* **上传后乱码**：请提供样例文件；可针对性设定编码或切换解析策略（如 Tika）。
* **Quill 控制台警告**：已使用 Quill 2（无 `DOMNodeInserted` 废弃警告）。

---

## 📜 许可

自定义或 MIT（根据你的项目要求填）。
