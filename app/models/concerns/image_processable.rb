module ImageProcessable
  # エラーの出力を行いたいのでStandardErrorクラスをImageProcessingErrorクラスに継承
  class ImageProcessingError < StandardError; end

  module_function

  # 画像処理メソッド。image_ioにはparams[:post][:image]の中の一時ファイルを渡す
  # widthには横幅の最大値を渡す
  def process_and_transform_image(image_io, width)
    return unless image_io.present?

    begin
      # 画像処理の部分。横幅に合うようにアスペクト比を維持してリサイズ、その後webpに変換する
      processed_image = ImageProcessing::Vips
        .source(image_io)
        .resize_to_fit(width, nil)
        .convert("webp")
        .saver(strip: true, quality: 85)
        .call

      # ActionDispatch::Http::UploadedFileを返す
      ActionDispatch::Http::UploadedFile.new(
        tempfile: processed_image,
        filename: "#{File.basename(image_io.original_filename, '.*')}.webp",
        type: "image/webp"
      )
    rescue => e
      Rails.logger.error "Image processing error: #{e.message}"
      raise ImageProcessingError, "画像の処理中にエラーが発生しました: #{e.message}"
    end
  end
end
