class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user, only: [:update_wechat_userinfo, :update_gps, :update_name, :info, :sms_verification_code, :bind_mobile, :create, :index]
  before_action :find_device, only: [:index, :show, :create]

  def wechat_auth
    user = User.find_or_create_by_wechat(params[:code])
    respond_to do |format|
      format.json do
        if user
          render json: { status: 1, message: "ok", data: { openid: user.open_id, user_id: user.id, mobile: user.mobile.blank? ? "" : user.mobile, device_num: user.device_count } }
        else
          render json: { status: 0, message: "授权失败" }
        end
      end
    end
  end

  def index
    page = params[:page].blank? ? 1 : params[:page].to_i
    datas = []
    users = User.users_by_device(@device, @user, page, 10)
    now = Time.now
    wday = now.wday
    users.each do |user|
      total_count = user.finger_count + user.password_count + user.card_count + user.temp_pwd_count
      if user.has_ble_setting
        if user.ble_type==BleSetting::TYPES[:forever]
          content = "蓝牙永久权限"
        elsif user.ble_type==BleSetting::TYPES[:duration]
          if now >= user.start_at && now <= user.end_at
            content = "蓝牙生效中"
          elsif now < user.start_at
            content = "蓝牙未生效"
          elsif now > user.end_at
            content = "蓝牙已过期"
          end
        elsif user.ble_type==BleSetting::TYPES[:cycle]
          weeks = user.cycle.gsub("-", "").gsub("\n", "").split(" ").map(&:to_i)
          if weeks.include?(wday) && (now.strftime('%H:%M') >= user.cycle_start_at) && (now.strftime('%H:%M') <= user.cycle_end_at)
            content = "蓝牙生效中"
          else
            content = "蓝牙未生效"
          end
        end
      else
        content = total_count==0 ? "尚未添加任何使用权限" : ""
      end
      datas << { id: user.id, name: user.nickname, mobile: user.mobile, avatar_url: user.avatar_url.blank? ? "" : user.avatar_url, is_admin: user.ownership!=UserDevice::OWNERSHIP[:user], 
        finger_count: user.finger_count, password_count: user.password_count, card_count: user.card_count,
        temp_pwd_count: user.temp_pwd_count, has_ble_setting: user.has_ble_setting, 
        content: content }
    end
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, device_id: @device.id, total_pages: users.total_pages, current_page: page, total_count: users.total_count }
      end
    end
  end

  def show
    page = params[:page].blank? ? 1 : params[:page].to_i
    user = User.select("users.id, users.open_id, users.nickname, users.mobile, users.avatar_url, user_devices.ownership").joins(:user_devices).where(:id => params[:id], :user_devices => { device_id: @device.id }).first
    users = DeviceUser.where("device_id=? and user_id=?", @device.id, user.id).page(page).per(10)
    is_admin, has_ble_setting, ble_status = is_can_open_lock(@device, user)
    result = []
    users.each do |user|
      result << { id: user.id, type: user.device_type, num: user.device_num, username: user.username }
    end
    datas = { id: user.id, name: user.nickname, mobile: user.mobile,
      binded: !user.open_id.blank?,
      avatar_url: user.avatar_url.blank? ? "" : user.avatar_url,
      is_admin: user.ownership != UserDevice::OWNERSHIP[:user],
      has_ble_setting: has_ble_setting, ble_status: ble_status }
    respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: datas, users: result, total_pages: users.total_pages, current_page: page }
      end
    end
  end

  def create
    user = User.where(:mobile => params[:mobile]).first
    respond_to do |format|
      format.json do
        unless user
          user = User.new(nickname: params[:name], mobile: params[:mobile], gender: 1, device_count: 1)
          if user.valid?
            user.save
            UserDevice.create(:author_id => @user.id, :user_id => user.id, :device_id => @device.id, :ownership => UserDevice::OWNERSHIP[:user])
            render json: { status: 1, message: "ok" }
          else
            render json: { status: 0, message: user.errors.full_messages.to_sentence }
          end
        else
          if user.id == @user.id
            render json: { status: 0, message: "亲，不能添加自己" }
          else
            ud = UserDevice.where(:user_id => user.id, :device_id => @device.id).first
            if ud
              ud.update_attributes({:author_id => @user.id, :visible => true, :ownership => UserDevice::OWNERSHIP[:user]})
            else
              UserDevice.create(:author_id => @user.id, :user_id => user.id, :device_id => @device.id, :ownership => UserDevice::OWNERSHIP[:user], :visible => true)
            end
            user.update_attribute(:device_count, user.device_count+1)
            render json: { status: 1, message: "ok" }
          end 
        end
      end
    end
  end

  def update_wechat_userinfo
    respond_to do |format|
      format.json do
        if @user
          @user.update_attributes({:country => params[:country], :province => params[:province], :city => params[:city],
            :nickname => params[:nickName], :gender => params[:gender], :avatar_url => params[:avatarUrl]})
          render json: { status: 1, message: "ok", user_id: @user.id, device_num: @user.device_count }
        else
          render json: { status: 0, message: "更新用户信息失败" }
        end
      end
    end
  end

  def update_gps
    respond_to do |format|
      format.json do
        if @user
          @user.update_attributes({:latitude => params[:latitude], :longitude => params[:longitude]})
          render json: { status: 1, message: "ok" }
        else
          render json: { status: 0, message: "没用找到用户记录" }
        end
      end
    end
  end

  def info
    respond_to do |format|
      format.json do
        if @user
          render json: { status: 1, message: "ok", 
            data: {
              id: @user.id,
              device_num: @user.device_count,
              user: {
                nickName: @user.nickname,
                avatarUrl: @user.avatar_url,
                country: @user.country,
                province: @user.province,
                city: @user.city,
                gender: @user.gender
              }
            }
          } 
        else
          render json: { status: 0, message: "获取用户信息失败" }
        end
      end
    end
  end

  def sms_verification_code
    respond_to do |format|
      format.json do
        unless check_mobile(params[:mobile])
          render json: { status: 0, message: "请输入有效的手机号", data: {} } and return
        end
        unless %W(1 2 3 4).include?(params[:type].to_s)
          render json: { status: 0, message: "type参数错误", data: {} } and return
        end

        # 检查手机是否符合获取验证码的要求
        type = params[:type].to_i
        user = User.find_by(mobile: params[:mobile])
        if type == 1 # 注册
          if user.present?
            render json: { status: 0, message: "#{params[:mobile]}已经注册", data: {} } and return
          end
        elsif type == 4 # 绑定、修改手机号码
          if user.present? && !user.open_id.blank?
            render json: { status: 0, message: "#{params[:mobile]}已经被占用", data: {} } and return
          end
        else # 重置密码和修改密码
          if user.blank?
            render json: { status: 0, message: "#{params[:mobile]}未注册", data: {} } and return
          end
        end

        # 1分钟内多次提交检测
        sym = "#{params[:mobile]}_#{params[:type]}".to_sym
        if session[sym] && ( Time.now.to_i - session[sym].to_i ) < 60 + rand(3)
          render json: { status: 0, message: "同一手机号1分钟内只能获取一次验证码，请稍后重试", data: {} } and return
        end

        session[sym] = Time.now.to_i

        # 同一手机一天最多获取5次验证码
        log = SendSmsLog.where('mobile = ? and send_type = ?', params[:mobile], params[:type]).first
        if log.blank?
          log = SendSmsLog.create!(mobile: params[:mobile], send_type: params[:type], first_sms_sent_at: Time.now)
        else
          dt = Time.now.to_i - log.first_sms_sent_at.to_i
          if dt > 24 * 3600 # 超过24小时都要重置发送记录
            log.sms_total = 0
            log.first_sms_sent_at = Time.now
            log.save!
          else # 24小时以内
            if log.sms_total.to_i >= 5 # 达到5次
              render json: { status: 0, message: "同一手机号24小时内只能获取5次验证码，请稍后再试", data: {} } and return
            end
          end
        end

        # 获取验证码并发送
        code = AuthCode.where('mobile = ? and verified = ? and auth_type = ?', params[:mobile], false, type).first
        code = AuthCode.create!(mobile: params[:mobile], auth_type: type, code: rand(1000..9999).to_s) if code.blank?
      
        if code
          result = send_sms(User::YUNPIAN_API_KEY, params[:mobile], code.code, "获取验证码失败", log)
          render json: result
        else
          render json: { status: 0, message: "验证码生成错误，请重试", data: {} }
        end
      end
    end
  end

  def bind_mobile
    respond_to do |format|
      format.json do
        unless check_mobile(params[:mobile])
          render json: { status: 0, message: "请输入有效的手机号", data: {} } and return
        end
        unless %W(1 2 3 4).include?(params[:type].to_s)
          render json: { status: 0, message: "type参数错误", data: {} } and return
        end
        user = User.find_by(mobile: params[:mobile])
        if user.present?
          unless user.open_id.blank?
            render json: { status: 0, message: "#{params[:mobile]}已被绑定", data: {} } and return
          else
            hash = @user.dup.attributes.except("id", "created_at", "updated_at", "nickname", "mobile") if @user
            User.transaction do
              if @user.id!=user.id
                @user.destroy
                user.update_attributes(hash) unless hash.nil?
                hash = nil
              end
            end
          end
          ac = AuthCode.where('mobile = ? and code = ? and auth_type = ? and verified = ?', params[:mobile], params[:verification_code], params[:type], false).first
          if ac.blank?
            render json: { status: 0, message: "验证码无效", data: {} } and return
          else
            ac.update_attribute(:verified, true)
            render json: { status: 1, message: "ok", user_id: user.id, device_num: user.device_count }
          end
        else
          ac = AuthCode.where('mobile = ? and code = ? and auth_type = ? and verified = ?', params[:mobile], params[:verification_code], params[:type], false).first
          if ac.blank?
            render json: { status: 0, message: "验证码无效", data: {} } and return
          else
            ac.update_attribute(:verified, true)
            if !@user.nil? && @user.mobile!=params[:mobile]
              @user.update_attribute(:mobile, params[:mobile]) 
            end
            render json: { status: 1, message: "ok", user_id: @user.id, device_num: @user.device_count }
          end
        end
      end
    end
  end

  def update_name
    respond_to do |format|
      format.json do
        if @user
          @user.update_attribute(:nickname, params[:name].strip)
          render json: { status: 1, message: "ok" }
        else
          render json: { status: 0, message: "没用找到用户" }
        end
      end
    end
  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end

    def find_device
      @device = Device.find_by(id: params[:device_id])
    end
    
    def check_mobile(mobile)
      return false if mobile.length != 11
      mobile =~ /\A1[3|4|5|7|8|9][0-9]\d{4,8}\z/
    end

    def send_sms(api_key, mobile, sms_code, error_msg, log)
      url = "https://sms.yunpian.com/v2/sms/tpl_single_send.json"
      tpl_id = 1689800
      tpl_value = "#code#=#{sms_code}"
      options = "apikey=#{api_key}&mobile=#{mobile}&tpl_id=#{tpl_id}&tpl_value=#{tpl_value}"
      hash = {}
      
      begin
        response = RestClient.post(url, options)
        result = JSON.parse(response.body)

        if result['code'].to_i == 0
          log.update_attribute(:sms_total, log.sms_total + 1)
          hash = { status: 1, message: "ok" }
        else
          if result['code'].to_i == 9 || result['code'].to_i == 17
            hash = { status: 0, message: result['msg'] }
          else
            if session && result['code'].to_i == 103
              # 发送失败，更新每分钟发送限制
              sym = "#{mobile}_#{params[:type]}".to_sym
              session.delete(sym)
            end
            hash = { status: 0, message: result['msg'] }
          end
        end
      rescue => e
        p e.message
        hash = { status: 0, message: "发送失败，请稍后重试" }
      end
      hash
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