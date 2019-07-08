class Api::V1::DevicesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user
  before_action :find_device, only: [:show, :unbind, :cmd, :rename, :users]

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    @devices = Device.joins(:user_devices).where(:user_devices => { user_id: @user.id, visible: true }).reload.page(page).per(10)
    @devices.each do |dv|
      datas << { id: dv.id,
                 uuid: dv.uuid, name: dv.alias,
                 status_id: dv.status_id,
                 mac: dv.mac,
                 token: dv.token }
    end
    @carousels = []
    home_carousels = Carousel.visible.home.limit(1)
    unless home_carousels.empty?
      home_carousels[0].images.each_with_index do |image, index|
        @carousels << { id: index, url: image.url(:large) }
      end
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, carousels: @carousels, total_pages: @devices.total_pages, current_page: page, total_count: @devices.total_count }
      end
    end
  end

  def show
    @carousels = []
    device_carousels = Carousel.visible.device.limit(1)
    unless device_carousels.empty?
      device_carousels[0].images.each_with_index do |image, index|
        @carousels << { id: index, url: image.url(:large) }
      end
    end
    respond_to do |format|
      format.json do
        if @device
          data = { id: @device.id, name: @device.alias,
                   mac: @device.mac, token: @device.token,
                   status_id: @device.status_id, uuid: @device.uuid,
                   open_num: @device.open_num, low_qoe: @device.low_qoe,
                   is_admin: @device.is_admin?(@user.id), 
                   imei: @device.imei,
                   created_at: @device.created_at.strftime('%Y-%m-%d') }
          render json: { status: 1, message: "ok", data: data, carousels: @carousels } 
        else
          render json: { status: 0, message: "no recored yet" } 
        end
      end
    end
  end

  def bind
    respond_to do |format|
      format.json do
        Device.transaction do
          device = Device.where(:mac => params[:mac].strip).first
          unless device
            token = Digest::MD5.hexdigest(params[:mac].strip + Device::SALT)
            device = Device.create(:mac => params[:mac].strip, :token => token, :uuid => token[0..3], :status_id => DeviceStatus::BINDED)
            ##todo 设置权限
          else
            if device.status_id == DeviceStatus::UNBIND
              @device.update_attribute(:status_id, DeviceStatus::BINDED)
            end
          end
          user_device = UserDevice.where(:device => device, :ownership => UserDevice::OWNERSHIP[:super_admin]).first
          unless user_device
            UserDevice.create(:user => @user, :device => device, :ownership => UserDevice::OWNERSHIP[:super_admin])
          else
            ud = UserDevice.where(:user_id => @user.id, :device_id => device.id).first
            unless ud
              render json: { status: 0, message: "亲，设备已被绑定", data: {} } and return
            else
              ud.update_attribute(:visible, true) unless ud.visible
            end
          end
          Message.where(:user_id => @user.id, :device_id => device.id).last_week.update_all(is_deleted: false)
          render json: { status: 1, message: "", data: {} }
        end
      end
    end
  end

  def unbind
    respond_to do |format|
      format.json do
        if @device
          user_device = UserDevice.where(:user => @user, :device => @device).first
          if user_device.is_admin?
            @device.update_attribute(:status_id, DeviceStatus::BINDED)
            UserDevice.where(:device => device).update_all(ownership: UserDevice::OWNERSHIP[:user], visible: false)
            Message.where(:device_id => device.id).update_all(is_deleted: false)
          else
            user_device.update_attributes({:visible => false, :ownership => UserDevice::OWNERSHIP[:user]})
          end
          render json: { status: 1, message: "ok" }
        else
          render json: { status: 0, message: "设备不存在" }
        end
      end
    end
  end

  def rename
    respond_to do |format|
      format.json do
        if @device
          @device.update_attribute(:alias, params[:name].strip)
          render json: { status: 1, message: "ok", data: { name: params[:name].strip } } 
        else
          render json: { status: 0, message: "no recored yet" } 
        end
      end
    end
  end

  def cmd
    content = Message::CMD_NAMES[params[:lock_cmd]]
    username = ""
    unless params[:lock_num].blank?
      du = DeviceUser.where(device_id: @device.id, device_type: params[:lock_type], device_num: params[:lock_num]).first
      if du
        username = du.username
        content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]}-#{username})"
      else
        if params[:lock_cmd]=="password_open_door" || params[:lock_cmd]=="remove_password"
          du = DeviceUser.where(device_id: @device.id, device_type: 4, device_num: params[:lock_num]).first
          if du
            username = du.username
            content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]}-#{username})"
          else
            content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]})"
          end
        else
          content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]})"
        end
      end
    end
    if params[:lock_cmd]=="get_qoe"
      content = Message::CMD_NAMES[params[:lock_cmd]]
      content = params[:lock_num].to_i==1 ? content + " 电量低" : content + " 电量充足"
      @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], content: content, lock_type: params[:lock_type])
      @device.update_attributes({:status_id => 2, :low_qoe => (params[:lock_num].to_i==1)})
    elsif params[:lock_cmd]=="get_open_num"
      content = Message::CMD_NAMES[params[:lock_cmd]] + "(#{params[:lock_num]})"
      @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], content: content, lock_type: params[:lock_type], lock_num: params[:lock_num])
      if @device.open_num > params[:lock_num].to_i
        @device.update_attributes({:status_id => 2, :open_num => @device.open_num + params[:lock_num].to_i})
      else
        @device.update_attributes({:status_id => 2, :open_num => params[:lock_num].to_i})
      end
    elsif !params[:open_time].blank?
      if params[:lock_num].blank?
        @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], content: content, lock_type: params[:lock_type], created_at: params[:open_time])
      else
        @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], oper_username: username, content: content, lock_type: params[:lock_type], lock_num: params[:lock_num], created_at: params[:open_time])
      end
    else
      if params[:lock_num].blank?
        if params[:lock_cmd]=="ble_open_door"
          content = content + "(#{@user.name})"
        end
        @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], content: content, lock_type: params[:lock_type])
      else
        if params[:lock_cmd].include?("reg")
          username = params[:user_name].blank? ? ("##{params[:lock_num]}" + DeviceUser::TYPENAME[params[:lock_type]]) : params[:user_name].strip()
          content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]}-#{username})"
          @device.update_attributes({:status_id => 2}) if @device.status_id != 2
          #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
        end
        @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], oper_username: username, content: content, lock_type: params[:lock_type], lock_num: params[:lock_num])
      end
    end
    if params[:lock_cmd].include?("remove")
      #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
      du = DeviceUser.where(device_id: @device.id, device_type: params[:lock_type], device_num: params[:lock_num]).first
      if params[:lock_type].to_i==2
        if du
          du.destroy
        else
          du = DeviceUser.where(device_id: @device.id, device_type: 4, device_num: params[:lock_num]).first
          du.destroy if du
        end
      else
        du.destroy if du
      end
    elsif params[:lock_cmd].include?("reg")
      username = params[:user_name].blank? ? ("##{params[:lock_num]}" + DeviceUser::TYPENAME[params[:lock_type]]) : params[:user_name].strip()
      du = DeviceUser.new(device_id: @device.id, device_type: params[:lock_type], device_num: params[:lock_num], username: username)
      du.save if du.valid?
    elsif params[:lock_cmd]=="init"
      #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
      Device.transaction do
        @device.update_attribute(:status_id, DeviceStatus::BINDED)
        UserDevice.where(:device => @device).update_all(ownership: UserDevice::OWNERSHIP[:user], visible: false)
        Message.where(:device_id => @device.id).update_all(is_deleted: false)
      end
    end
    respond_to do |format|
      format.json do
        if @msg.valid?
          @msg.save
          render json: { status: 1, message: "ok" } 
        else
          render json: { status: 0, message: @msg.errors.full_messages.to_sentence } 
        end
      end
    end
  end

  def users
    page = params[:page].blank? ? 1 : params[:page].to_i
    users = DeviceUser.where(device_id: @device.id, device_type: params[:lock_type]).reload.page(page).per(10)
    datas = []
    users.each do |du|
      datas << { id: du.id, username: du.username, device_num: du.device_num }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: users.total_pages, current_page: page, total_count: users.total_count }
      end
    end
  end

  def edit_user
    du = DeviceUser.where(id: params[:id], device_num: params[:num]).first
    respond_to do |format|
      format.json do
        if du && du.update_attribute(:username, params[:name].strip)
          render json: { status: 1, message: "ok" }
        else
          render json: { status: 0, message: "error" }
        end
      end
    end
  end

  def set_open_warn
    du = DeviceUser.where(id: params[:id], device_num: params[:num]).first
    respond_to do |format|
      format.json do
        if du
          du.update_attribute(:open_need_warn, !du.open_need_warn)
          render json: { status: 1, message: "ok", data: { open_need_warn: du.open_need_warn } }
        else
          render json: { status: 0, message: "error" }
        end
      end
    end
  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end

    def find_device
      @device = Device.joins(:user_devices).where(:user_devices => { user_id: @user.id }, :devices => { id: params[:device_id] }).first
    end
end