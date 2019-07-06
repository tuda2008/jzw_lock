class Api::V1::MessagesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    query_type = params[:query_type].blank? ? 1 : params[:query_type].to_i
    query = params[:query].blank? ? "" : params[:query].strip
    datas = []
    if params[:device_id]
      user_device = UserDevice.where(user_id: @user.id, device_id: params[:device_id]).first
      if user_device && user_device.is_admin?
        if query_type == 1
          if query.length > 0
            @messages = Message.visible.today.where("device_id=? and content like ?", params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.today.where(device_id: params[:device_id]).page(params[:page]).per(10)
          end
        elsif query_type == 2
          if query.length > 0
            @messages = Message.visible.yesterday.where("device_id=? and content like ?", params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.yesterday.where(device_id: params[:device_id]).page(params[:page]).per(10)
          end
        else
          if query.length > 0
            @messages = Message.visible.last_week.where("device_id=? and content like ?", params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.last_week.where(device_id: params[:device_id]).page(params[:page]).per(10)
          end
        end
      else
        if query_type == 1
          if query.length > 0
            @messages = Message.visible.today.where("user_id=? and device_id=? and content like ?", @user.id, params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.today.where(user_id: @user.id, device_id: params[:device_id]).page(params[:page]).per(10)
          end
        elsif query_type == 2
          if query.length > 0
            @messages = Message.visible.yesterday.where("user_id=? and device_id=? and content like ?", @user.id, params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.yesterday.where(user_id: @user.id, device_id: params[:device_id]).page(params[:page]).per(10)
          end
        else
          if query.length > 0
            @messages = Message.visible.last_week.where("user_id=? and device_id=? and content like ?", @user.id, params[:device_id], "%#{query}%").page(params[:page]).per(10)
          else
            @messages = Message.visible.last_week.where(user_id: @user.id, device_id: params[:device_id]).page(params[:page]).per(10)
          end
        end
      end
      @messages.each do |msg|
        datas << { id: msg.id, oper_cmd: Message::CMD_NAMES[msg.oper_cmd], content: msg.content,
                   created_at: query_type==3 ? msg.created_at.strftime('%m-%d %H:%M:%S') : msg.created_at.strftime('%H:%M:%S')}
      end
  	else
      if query_type == 1
        if query.length > 0
          @messages = Message.visible.today.where("user_id=? and content like ?", @user.id, "%#{query}%").includes(:device).page(params[:page]).per(10)
        else
          @messages = Message.visible.today.where(user_id: @user.id).includes(:device).page(params[:page]).per(10)
        end
      elsif query_type == 2
        if query.length > 0
          @messages = Message.visible.yesterday.where("user_id=? and content like ?", @user.id, "%#{query}%").includes(:device).page(params[:page]).per(10)
        else
          @messages = Message.visible.yesterday.where(user_id: @user.id).includes(:device).page(params[:page]).per(10)
        end
      else
        if query.length > 0
          @messages = Message.visible.last_week.where("user_id=? and content like ?", @user.id, "%#{query}%").includes(:device).page(params[:page]).per(10)
        else
          @messages = Message.visible.last_week.where(user_id: @user.id).includes(:device).page(params[:page]).per(10)
        end
      end
      @messages.each do |msg|
        datas << { id: msg.id, oper_cmd: Message::CMD_NAMES[msg.oper_cmd],
                   device_name: msg.device.name, content: msg.content,
                   created_at: query_type==3 ? msg.created_at.strftime('%m-%d %H:%M:%S') : msg.created_at.strftime('%H:%M:%S')}
      end
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