# app/services/ai/analyzer_service.rb
module Ai
  class AnalyzerService
    # 返回问题项数组：[{id:, start:, end:, message:, suggestion:, severity:}]
    def self.call(text)
      # 这里先 mock 两个问题；你接入外部 API 后，构造成同样的结构即可
      # start/end 为基于 text 的字符偏移（UTF-16 代码单元在 JS 内也兼容）
      sample = []
      if (idx = text.index("貴單位"))
        sample << {
          id: SecureRandom.uuid,
          start: idx,
          end: idx + 3,
          message: "用语不规范：建议用“贵单位”",
          suggestion: "贵单位",
          severity: "minor"
        }
      end
      if (idx = text.index("請貴部門"))
        sample << {
          id: SecureRandom.uuid,
          start: idx,
          end: idx + 4,
          message: "公文书写建议：使用简体“请贵部门”",
          suggestion: "请贵部门",
          severity: "normal"
        }
      end
      sample
    end
  end
end
