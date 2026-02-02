// app/javascript/controllers/proofread_controller.js
import { Controller } from "@hotwired/stimulus"

// 用 Quill 2（在布局里用 CDN 已引入 quill@2）
export default class extends Controller {
    static targets = ["editor", "issuesPanel"]

    // ✅ 新增 initialContentValue
    static values = {
        analyzeUrl: String,
        initialContent: String
    }

    connect() {
        // 初始化 Quill
        this.quill = new Quill(this.editorTarget, {
            theme: "snow",
            modules: {
                toolbar: [
                    [{ header: [1, 2, 3, false] }],
                    ["bold", "italic", "underline", "strike"],
                    [{ list: "ordered" }, { list: "bullet" }],
                    ["blockquote", "code-block"],
                    ["link", "clean"]
                ]
            },
            placeholder: "在此输入公文内容…"
        })

        // ✅ 把后端解析好的正文塞到编辑器里
        const initial = (this.initialContentValue || "").trim()
        if (initial.length > 0) {
            // 纯文本模式，保留换行
            this.quill.setText(initial)
            // 光标放到开头或结尾都行，这里放到开头
            this.quill.setSelection(0, 0, "silent")
        }

        // 存每个问题的 {index, length, suggestion}
        this.issueRanges = new Map()
    }

    // === 触发 AI 分析 ===
    async analyze() {
        const text = this.quill.getText()
        if (!text.trim()) {
            this.issuesPanelTarget.innerHTML =
                `<div class="text-gray-500">正文为空，无法分析。</div>`
            return
        }
        this.clearAllHighlights()

        const res = await fetch(this.analyzeUrlValue, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": this.csrfToken()
            },
            body: JSON.stringify({ text })
        })

        const data = await res.json()
        const issues = data.issues || []

        this.renderIssues(issues)
        this.applyHighlights(issues)
    }

    csrfToken() {
        const m = document.querySelector("meta[name='csrf-token']")
        return m ? m.content : ""
    }

    // === 左侧列表渲染 ===
    renderIssues(issues) {
        if (!issues.length) {
            this.issuesPanelTarget.innerHTML =
                `<div class="text-green-700 bg-green-50 border border-green-200 rounded p-3">
           未发现需要修改的内容。
         </div>`
            return
        }

        this.issuesPanelTarget.innerHTML = issues.map((it, idx) => `
      <div class="border rounded-lg p-3" data-issue-id="${it.id}">
        <div class="flex items-start justify-between gap-2">
          <div>
            <div class="text-sm font-medium">#${idx + 1} ${this.escape(it.message)}</div>
            ${it.suggestion
                ? `<div class="text-xs text-gray-500 mt-1">建议：${this.escape(it.suggestion)}</div>`
                : ""}
          </div>
          <span class="text-xs px-2 py-0.5 rounded bg-amber-100 text-amber-800">
            ${it.severity || "normal"}
          </span>
        </div>
        <div class="mt-2 flex gap-2">
          <button class="px-2 py-1 text-xs bg-gray-100 hover:bg-gray-200 rounded"
                  data-action="click->proofread#ignore" data-id="${it.id}">忽略</button>
          ${it.suggestion
                ? `<button class="px-2 py-1 text-xs bg-indigo-600 hover:bg-indigo-700 text-white rounded"
                  data-action="click->proofread#replace" data-id="${it.id}">替换</button>`
                : ""}
          <button class="ml-auto px-2 py-1 text-xs text-indigo-600 hover:underline"
                  data-action="click->proofread#jump" data-id="${it.id}">定位</button>
        </div>
      </div>
    `).join("")
    }

    // === 高亮正文 ===
    applyHighlights(issues) {
        issues.forEach(it => {
            const index = it.start
            const length = Math.max(0, it.end - it.start)
            if (length <= 0) return

            this.issueRanges.set(it.id, {
                index,
                length,
                suggestion: it.suggestion || ""
            })

            this.quill.formatText(index, length, { background: "#fde68a" }) // amber-200
        })
    }

    clearAllHighlights() {
        const len = this.quill.getLength()
        this.quill.formatText(0, len, { background: false })
        this.issueRanges.clear()
    }

    // === 列表动作：忽略 ===
    ignore(ev) {
        const id = ev.currentTarget.dataset.id
        const r = this.issueRanges.get(id)
        if (!r) return

        this.quill.formatText(r.index, r.length, { background: false })
        this.issueRanges.delete(id)

        const card = this.issuesPanelTarget.querySelector(`[data-issue-id="${id}"]`)
        if (card) card.remove()
    }

    // === 列表动作：替换 ===
    replace(ev) {
        const id = ev.currentTarget.dataset.id
        const r = this.issueRanges.get(id)
        if (!r) return

        const { index, length, suggestion } = r
        this.quill.deleteText(index, length)
        this.quill.insertText(index, suggestion || "", "user")

        // 简单平移后面 issue 的 index
        const delta = (suggestion || "").length - length
        if (delta !== 0) {
            for (const [k, v] of this.issueRanges.entries()) {
                if (v.index > index) {
                    this.issueRanges.set(k, { ...v, index: v.index + delta })
                }
            }
        }

        this.issueRanges.delete(id)
        const card = this.issuesPanelTarget.querySelector(`[data-issue-id="${id}"]`)
        if (card) card.remove()
    }

    // === 列表动作：定位 ===
    jump(ev) {
        const id = ev.currentTarget.dataset.id
        const r = this.issueRanges.get(id)
        if (!r) return

        const { index, length } = r
        const len = Math.max(1, length)

        this.quill.setSelection(index, len, "user")
        this.quill.formatText(index, len, { background: "#facc15" }) // 高亮一下
        setTimeout(
            () => this.quill.formatText(index, len, { background: "#fde68a" }),
            350
        )
    }

    escape(s) {
        return String(s || "").replace(/[&<>"']/g, m => ({
            "&": "&amp;",
            "<": "&lt;",
            ">": "&gt;",
            "\"": "&quot;",
            "'": "&#39;"
        }[m]))
    }
}
