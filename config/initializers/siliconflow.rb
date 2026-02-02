Rails.application.config.x.siliconflow = ActiveSupport::InheritableOptions.new(
  endpoint: "https://api.siliconflow.cn/v1/chat/completions",
  model:    "Qwen/Qwen3-Omni-30B-A3B-Instruct",
  timeout:  25
)
