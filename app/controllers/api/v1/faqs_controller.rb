class Api::V1::FaqsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    @faqs = Faq.visible.page(params[:page]).per(10)
    @faqs.each do |faq|
      datas << { id: faq.id, title: faq.title }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: @faqs.total_pages, current_page: page, total_count: @faqs.total_count }
      end
    end
  end

  def show
    data = []
    images = []
    @faq = Faq.visible.find(params[:id])
    respond_to do |format|
      format.json do
        if @faq
          unless @faq.images.empty?
            @faq.images.each_with_index do |image, index|
              images << { id: index, url: image.url(:large) }
            end
          end
          data = { id: @faq.id, title: @faq.title, content: @faq.content, images: images }
          render json: { status: 1, message: "ok", data: data }
        else
          render json: { status: 0, message: "您访问的页面不存在" }
        end
      end
    end
  end

  def carousels
    @carousels = []
    home_carousels = Carousel.visible.home.limit(1)
    unless home_carousels.empty?
      home_carousels[0].images.each_with_index do |image, index|
        @carousels << { id: index, url: image.url(:thumb) }
      end
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", carousels: @carousels }
      end
    end
  end
end