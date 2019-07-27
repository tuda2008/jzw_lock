class Api::V1::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    query = params[:query_date].blank? ? "" : params[:query_date].strip
    datas = []
    if query.length > 0
      @messages = Message.visible.where("device_id=? and date(created_at)=?", params[:device_id], query]).includes(:device).page(params[:page]).per(10)
    else
      @messages = Message.visible.where(device_id: params[:device_id]).includes(:device, :user).page(params[:page]).per(10)
    end
    @messages.each do |msg|
      datas << { id: msg.id, oper_cmd: Message::CMD_NAMES[msg.oper_cmd], content: msg.content,
                  username: msg.user.nickname,
                  avatar_url: msg.user.avatar_url.blank? ? "" : msg.user.avatar_url,
                  created_at_year: msg.created_at.strftime('%Y'),
                  created_at_date: msg.created_at.strftime('%m-%d'),
                  created_at_datetime: msg.created_at.strftime('%H:%M:%S') }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: @messages.total_pages, current_page: page }
      end
    end
  end

  def show
    @message = Message.where(id: params[:message_id]).first
  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end
end