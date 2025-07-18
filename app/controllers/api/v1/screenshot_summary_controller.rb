class Api::V1::ScreenshotSummaryController < ApplicationController
  require 'rtesseract'
  require 'tempfile'

  def create
    return render json: { error: "No file uploaded" }, status: :bad_request unless params[:image]

    tempfile = Tempfile.new(['screenshot', '.png'])
    tempfile.binmode
    tempfile.write(params[:image].read)
    tempfile.rewind

    image = RTesseract.new(tempfile.path)
    extracted_text = image.to_s

    summary = summarize_text(extracted_text)
    page_type = detect_page_type(extracted_text)

    render json: {
      text: extracted_text.strip,
      summary: summary,
      page_type: page_type
    }
  ensure
    if params[:image] != nil
      tempfile.close
      tempfile.unlink
    end
  end

  private

  def summarize_text(text)
    lines = text.split("\n").reject(&:blank?)
    lines.length > 5 ? lines[0..2].join(" ") + "..." : text
  end

  def detect_page_type(text)
    text_down = text.downcase
    return "invoice" if text_down.include?("invoice") || text_down.include?("total")
    return "social" if text_down.include?("likes") || text_down.include?("followers")
    return "article" if text_down.include?("author") || text_down.include?("published")
    "unknown"
  end
end
