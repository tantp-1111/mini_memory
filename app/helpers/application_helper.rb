module ApplicationHelper
  # Flashメッセージの種類に応じたCSSクラスを返す
  def flash_class_for(type)
    case type.to_s
    when "notice"
      "success"
    when "alert"
      "error"
    else
      type.to_s
    end
  end
end
