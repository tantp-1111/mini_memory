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

  def default_meta_tags
    {
      site: "minimemory",
      title: (content_for?(:title) ? content_for(:title) : "捨てられない思い出を記録するアプリ"),
      reverse: true,
      charset: "utf-8",
      description: "minimemoryを使えば、捨てられない小さなモノの大切な思い出を簡単に記録して共有できます。",
      keywords: "思い出,記録,共有,こども,家族",
      canonical: "#{request.base_url}#{request.path}",
      separator: " | ",
      og: {
        site_name: :site,
        title: :title,
        description: :description,
        type: "website",
        url: "#{request.base_url}#{request.path}",
        image: ogp_image_url,
        locale: "ja_JP"
      },
      twitter: {
        card: "summary_large_image", # Xで表示する場合は大きいカードを使用
        image: ogp_image_url
      }
    }
  end

  def ogp_image_url
    cloud_name = Rails.application.credentials.dig(:cloudinary, :cloud_name)
    if @memory&.image&.attached? && cloud_name.present?
      public_id = @memory.image.key
      return "https://res.cloudinary.com/#{cloud_name}/image/upload/#{public_id}.jpeg" if public_id.present?
    end
    image_url("minimemory_ogp.png")
  end
end
