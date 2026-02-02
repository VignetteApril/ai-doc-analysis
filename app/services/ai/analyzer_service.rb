# frozen_string_literal: true

require "securerandom"
require "json"

module Ai
  class AnalyzerService
    # 输入：纯文本
    # 输出：[{ id:, start:, end:, message:, suggestion:, severity: }, ...]
    def self.call(text)
      new(text).call
    end

    def initialize(text)
      @text = text.to_s
    end

    def call
      return [] if @text.strip.empty?

      client = Ai::SiliconflowClient.new
      sys_prompt = <<~PROMPT
        你是中文公文的语言校对助手。请在给定“全文”中找出需要修改或优化的片段，并输出一个 JSON 数组 issues。
        每个元素格式如下（严格按键名输出）：
        {
          "id": string,                   # 唯一ID
          "start": number,                # 片段在“全文”里的起始下标，按 JavaScript 的 String.length 计数（UTF-16 码元）
          "end": number,                  # 结束下标（不含），同上计数方式
          "span": string,                 # 需要修改的“原文片段”（必须 exakt 出现在全文中）
          "message": string,              # 问题说明
          "suggestion": string,           # 建议替换文本；如无替换建议可给空字符串
          "severity": "minor"|"major"|"critical"
        }
        要求：
        - 仅输出 JSON，不要包含其他文字或代码块标记。
        - start/end 必须与“span”在全文中的位置一致（按 JS 的 UTF-16 索引）。
        - 如遇多处相同片段，请将该 issue 的 start/end 指向“最先出现的那一处”。
      PROMPT

      user_prompt = <<~USER
        全文如下（请基于这份全文做定位）：

        #{@text}
      USER

      resp = client.chat([
        { role: "system", content: sys_prompt },
        { role: "user",   content: user_prompt }
      ], max_tokens: 2048, temperature: 0)

      raw = resp.dig("choices", 0, "message", "content").to_s

      issues = safe_parse_issues_json(raw)
      normalize_ranges!(issues, @text)
    rescue Ai::SiliconflowClient::Error => e
      Rails.logger.error("[AnalyzerService] SiliconFlow error: #{e.message}")
      []
    end

    private

    # 尝试从模型输出中提取 JSON（有些模型会包裹 ```json ... ```）
    def safe_parse_issues_json(str)
      json_str =
        begin
          s = str.strip
          if s.start_with?("```")
            s = s.sub(/\A```json/i, "").sub(/\A```/, "").sub(/```\s*\z/, "")
          end
          JSON.parse(s)
        rescue
          # 兜底：尝试抓最外层的 [ ... ]
          if (m = str.match(/\[[\s\S]*\]/))
            JSON.parse(m[0])
          else
            []
          end
        end

      json_str.is_a?(Array) ? json_str : []
    rescue JSON::ParserError
      []
    end

    # 清洗/校正 start/end，确保不越界、不重叠异常
    # 将模型返回的 issues 标准化（并尽量回钉到正确位置）
    def normalize_ranges!(issues, full_text)
      full_js_len = js_code_units_length(full_text)

      issues.map! do |it|
        id     = (it["id"].presence || SecureRandom.hex(6))
        span   = it["span"].to_s
        # 模型提供的 JS 下标（若没有就置为 nil）
        s_js   = it["start"]
        e_js   = it["end"]

        # 先尝试“回钉”：优先在全文中按照“建议起点附近”搜索 span；
        # 若模型没给 start/end 或给错，就用 span 的第一次匹配位置。
        if span.present?
          approx_start = (s_js.is_a?(Numeric) ? s_js.to_i : 0)
          s_js2, e_js2 = reanchor_by_span(full_text, span, approx_start)
          s_js = s_js2 if s_js2
          e_js = e_js2 if e_js2
        end

        # 安全裁剪（JS 下标）
        s_js = s_js.to_i
        e_js = e_js.to_i
        s_js = 0              if s_js < 0
        e_js = 0              if e_js < 0
        s_js = full_js_len    if s_js > full_js_len
        e_js = full_js_len    if e_js > full_js_len
        e_js = s_js           if e_js < s_js

        {
          "id" => id,
          "start" => s_js,
          "end" => e_js,
          "span" => span,
          "message" => it["message"].to_s,
          "suggestion" => it["suggestion"].to_s,
          "severity" => (it["severity"].to_s.presence || "minor")
        }
      end
    end

    # 计算 JS 的 length（UTF-16 码元数）
    def js_code_units_length(str)
      # 每个 UTF-16 码元占 2 字节
      str.encode("UTF-16LE").bytesize / 2
    end

    # “回钉”：在全文中寻找 span 的 JS 下标位置。
    # 会优先从 approx_start 附近开始（向前小范围扫描），找不到则从全文开头找第一个出现。
    def reanchor_by_span(full_text, span, approx_start_js = 0)
      return [ nil, nil ] if span.empty?

      # 把 JS 码元下标转为 Ruby codepoint 下标做切片扫描。
      approx_cp = js_to_ruby_index(full_text, approx_start_js)

      # 先在 [approx_cp-200 .. approx_cp+200] 的窗口里找一次（避免落到后面的重复段）
      window = 200 # 可调整
      left_cp  = [ approx_cp - window, 0 ].max
      right_cp = [ approx_cp + window, full_text.length ].min
      slice    = full_text[left_cp...right_cp]
      hit_cp   = slice.index(span)

      if hit_cp
        s_cp = left_cp + hit_cp
        e_cp = s_cp + span.length
        return [ ruby_to_js_index(full_text, s_cp), ruby_to_js_index(full_text, e_cp) ]
      end

      # 再全局找第一次出现
      global_cp = full_text.index(span)
      if global_cp
        s_cp = global_cp
        e_cp = global_cp + span.length
        return [ ruby_to_js_index(full_text, s_cp), ruby_to_js_index(full_text, e_cp) ]
      end

      [ nil, nil ]
    end

    # Ruby codepoint 下标 -> JS UTF-16 码元下标
    def ruby_to_js_index(str, ruby_idx)
      cu = 0
      i  = 0
      str.each_codepoint do |cp|
        break if i >= ruby_idx
        cu += (cp > 0xFFFF ? 2 : 1) # 非BMP字符（如部分emoji）占 2 个码元
        i  += 1
      end
      cu
    end

    # JS UTF-16 码元下标 -> Ruby codepoint 下标（用于切片/搜索窗口）
    def js_to_ruby_index(str, js_idx)
      target = js_idx.to_i
      cu = 0
      i  = 0
      str.each_codepoint do |cp|
        step = (cp > 0xFFFF ? 2 : 1)
        break if cu + step > target
        cu += step
        i  += 1
      end
      i
    end
  end
end
