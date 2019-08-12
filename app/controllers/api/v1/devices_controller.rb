class Api::V1::DevicesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user
  before_action :find_device, only: [:show, :unbind, :cmd, :rename, :users]

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    @devices = Device.devices_by_user(@user, page, 10)
    @devices.each do |dv|
      datas << { id: dv.id, token: dv.token,
                 uuid: dv.uuid, name: dv.alias,
                 status_id: dv.status_id,
                 mac: dv.mac,
                 admin_name: dv.nickname,
                 is_admin: dv.ownership!=UserDevice::OWNERSHIP[:user] }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, total_pages: @devices.total_pages, current_page: page, total_count: @devices.total_count }
      end
    end
  end

  def show
    respond_to do |format|
      format.json do
        if @device
          is_admin, has_ble_setting, ble_status = is_can_open_lock(@device, @user)
          data = { id: @device.id, name: @device.alias,
                   mac: @device.mac, token: @device.token,
                   status_id: @device.status_id, uuid: @device.uuid,
                   open_num: @device.open_num, low_qoe: @device.low_qoe,
                   imei: @device.imei,
                   is_admin: is_admin,
                   has_ble_setting: has_ble_setting,
                   ble_status: ble_status,
                   created_at: @device.created_at.strftime('%Y-%m-%d') }
          render json: { status: 1, message: "ok", data: data } 
        else
          render json: { status: 0, message: "no record yet" } 
        end
      end
    end
  end

  def bind
    respond_to do |format|
      format.json do
        Device.transaction do
          is_admin = false
          device = Device.where(:mac => params[:mac].strip).first
          unless device
            token = Digest::MD5.hexdigest(params[:mac].strip + Device::SALT)
            device = Device.create(:mac => params[:mac].strip, :token => token, :uuid => token[0..3], :status_id => DeviceStatus::BINDED)
          end
          user_device = UserDevice.where(:device => device, :ownership => UserDevice::OWNERSHIP[:super_admin]).first
          unless user_device
            ud = UserDevice.where(:user_id => @user.id, :device_id => device.id).first
            unless ud
              UserDevice.create(:author_id => @user.id, :user_id => @user.id, :device_id => device.id, :ownership => UserDevice::OWNERSHIP[:super_admin])
            else
              ud.update_attributes({:author_id => @user.id, :visible => true, :ownership => UserDevice::OWNERSHIP[:super_admin]})
            end
            @user.update_attribute(:device_count, @user.device_count+1)
            is_admin = true
          else
            #if device.status_id == DeviceStatus::UNBIND
              #device.update_attribute(:status_id, DeviceStatus::BINDED)
            #end
            ud = UserDevice.where(:user_id => @user.id, :device_id => device.id).first
            unless ud
              render json: { status: 0, message: "亲，设备已被绑定", data: {} } and return
            else
              unless ud.visible
                @user.update_attribute(:device_count, @user.device_count+1)
                ud.update_attribute(:visible, true)
              else
                render json: { status: 2, message: "亲，您已经绑定过该设备了", data: { id: device.id, mac: device.mac, uuid: device.uuid, is_admin: is_admin } } and return
              end
            end
          end
          render json: { status: 1, message: "ok", data: { id: device.id, mac: device.mac, uuid: device.uuid, is_admin: is_admin } }
        end
      end
    end
  end

  def unbind
    respond_to do |format|
      format.json do
        if @device
          @user = User.find(params[:user_id]) if params[:user_id]
          user_device = UserDevice.where(:user => @user, :device => @device).first
          Device.transaction do
            if user_device.is_admin?
              user_device.remove_relevant_collections
            else
              total_count = user_device.finger_count + user_device.password_count + user_device.card_count + user_device.temp_pwd_count
              if total_count>0 || user_device.has_ble_setting
                render json: { status: 0, message: "请联系管理员先删除指纹、密码等设置后再删除" } and return
              else
                @user.decrement(:device_count)
                DeviceUser.where(:device_id => @device.id, :user_id => @user.id).each do |du|
                  du.destroy
                end
                user_device.destroy
              end
            end
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
          @device.update_attributes({:alias => params[:name].strip, :status_id => DeviceStatus::BINDED})
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
      du = DeviceUser.where(device_id: @device.id, user_id: params[:user_id], device_type: params[:lock_type], device_num: params[:lock_num]).first
      if du
        username = du.username
        content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]}-#{username})"
      else
        if params[:lock_cmd]=="password_open_door" || params[:lock_cmd]=="remove_password"
          du = DeviceUser.where(device_id: @device.id, user_id: params[:user_id], device_type: 4, device_num: params[:lock_num]).first
          if du
            if params[:lock_cmd]=="password_open_door"
              params[:lock_cmd]="temp_pwd_open_door"
            elsif params[:lock_cmd]=="remove_password"
              params[:lock_cmd]="remove_temp_password"
            end
            content = Message::CMD_NAMES[params[:lock_cmd]] + "(##{params[:lock_num]}-#{username})"
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
          @device.update_attributes({:status_id => DeviceStatus::BINDED}) if @device.status_id != DeviceStatus::BINDED
          #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
        end
        @msg = Message.new(user_id: @user.id, device_id: @device.id, oper_cmd: params[:lock_cmd], oper_username: username, content: content, lock_type: params[:lock_type], lock_num: params[:lock_num])
      end
    end
    if params[:lock_cmd].include?("remove")
      #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
      du = DeviceUser.where(device_id: @device.id, user_id: params[:user_id], device_type: params[:lock_type], device_num: params[:lock_num]).first
      if params[:lock_type].to_i==2
        ud = UserDevice.where(device_id: @device.id, user_id: params[:user_id]).first
        if du
          Device.transaction do
            du.destroy
            ud.update_attribute(:password_count, ud.password_count-1) if ud
          end
        else
          du = DeviceUser.where(device_id: @device.id, user_id: params[:user_id], device_type: 4, device_num: params[:lock_num]).first
          if du
            Device.transaction do
              du.destroy
              ud.update_attribute(:temp_pwd_count, ud.temp_pwd_count-1) if ud
            end
          end
        end
      else
        if du
          Device.transaction do
            du.destroy
            lock_type = params[:lock_type].to_i
            ud = UserDevice.where(device_id: @device.id, user_id: params[:user_id]).first
            if lock_type==1
              ud.update_attribute(:finger_count, ud.finger_count-1) if ud
            elsif lock_type==3
              ud.update_attribute(:card_count, ud.card_count-1) if ud
            elsif lock_type==5
              ud.update_attribute(:has_ble_setting, false) if ud
            end
          end
        end
      end
    elsif params[:lock_cmd].include?("reg")
      username = params[:user_name].blank? ? ("##{params[:lock_num]}" + DeviceUser::TYPENAME[params[:lock_type]]) : params[:user_name].strip()
      du = DeviceUser.new(device_id: @device.id, user_id: params[:user_id], device_type: params[:lock_type], device_num: params[:lock_num], username: username)
      if du.valid?
        du.save
        lock_type = params[:lock_type].to_i
        ud = UserDevice.where(device_id: @device.id, user_id: params[:user_id]).first
        if lock_type==1
          ud.update_attribute(:finger_count, ud.finger_count+1) if ud
        elsif lock_type==2
          ud.update_attribute(:password_count, ud.password_count+1) if ud
        elsif lock_type==3
          ud.update_attribute(:card_count, ud.card_count+1) if ud
        elsif lock_type==4
          ud.update_attribute(:temp_pwd_count, ud.temp_pwd_count+1) if ud
        elsif lock_type==5
          ud.update_attribute(:has_ble_setting, true) if ud
        end
      end
    elsif params[:lock_cmd]=="init"
      #WxMsgDeviceCmdNotifierWorker.perform_in(10.seconds, @device.all_admin_users.map(&:id), "[#{@device.name}]#{@user.name} #{content}", "text")
      Device.transaction do
        @msg.save if @msg.valid?
        @device.remove_relevant_collections
      end
    end
    respond_to do |format|
      format.json do
        if params[:lock_cmd]=="init" || @msg.valid?
          @msg.save if params[:lock_cmd]!="init"
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
      datas << { id: du.id, username: du.username, device_num: du.device_num, open_need_warn: du.open_need_warn }
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

    def is_can_open_lock(device, user)
      is_admin = false
      has_ble_setting = false
      ble_status = BleSetting::STATUSES[:disable]
      now = Time.now
      wday = now.wday

      user_device = UserDevice.where(:device => device, :user => user, :visible => true).first
      if user_device
        if user_device.ownership!=UserDevice::OWNERSHIP[:user]
          is_admin = true
          has_ble_setting = true
          ble_status = BleSetting::STATUSES[:enable]
        else
          has_ble_setting = user_device.has_ble_setting
          if has_ble_setting
            du = BleSetting.where(device_id: device.id, user_id: user.id).first
            unless du.nil?
              if du.ble_type== BleSetting::TYPES[:cycle]
                if du.cycle.include?(wday) && (now.strftime('%H:%M') >= du.cycle_start_at) && (now.strftime('%H:%M') <= du.cycle_end_at)
                  ble_status = BleSetting::STATUSES[:enable]
                end
              elsif du.ble_type== BleSetting::TYPES[:duration]
                if now >= du.start_at && now <= du.end_at
                  ble_status = BleSetting::STATUSES[:enable]
                elsif now > du.end_at
                  ble_status = BleSetting::STATUSES[:expire]
                elsif now < du.start_at
                  ble_status = BleSetting::STATUSES[:disable]
                end
              elsif du.ble_type== BleSetting::TYPES[:forever]
                ble_status = BleSetting::STATUSES[:enable]
              end
            end
          end
        end
      end
      return is_admin, has_ble_setting, ble_status
    end
end