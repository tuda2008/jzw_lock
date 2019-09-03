class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user, only: [:update_wechat_userinfo, :update_gps, :update_name, :info, :sms_verification_code, :bind_mobile, :create, :index]
  before_action :find_device, only: [:index, :show, :create]

  def wechat_auth
    user = User.find_or_create_by_wechat(params[:code])
    respond_to do |format|
      format.json do
        if user
          device_id = ""
          ud = UserDevice.where(:user_id => user.id, :visible => true).first
          device_id = ud.device_id unless ud.nil?
          render json: { status: 1, message: "ok", data: { openid: user.open_id, user_id: user.id, mobile: user.mobile.blank? ? "" : user.mobile, device_num: user.device_count, device_id: device_id } }
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
      total_count = user.finger_count.to_i + user.password_count.to_i + user.card_count.to_i + user.temp_pwd_count.to_i
      if user.has_ble_setting.to_i>0
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
          device_id = ""
          ud = UserDevice.where(:user_id => @user.id, :visible => true).first
          device_id = ud.device_id unless ud.nil?
          @user.update_attributes({:country => params[:country], :province => params[:province], :city => params[:city],
            :nickname => params[:nickName], :gender => params[:gender], :avatar_url => params[:avatarUrl]})
          render json: { status: 1, message: "ok", user_id: @user.id, device_num: @user.device_count, device_id: device_id }
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
          result = send_sms(User::YUNPIAN_API_KEY, User::TPL_ID, params[:mobile], code.code, "获取验证码失败", log)
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

  def update_mobile_and_name
    @user = User.find(params[:user_id])
    respond_to do |format|
      format.json do
        if @user
          @user.nickname = params[:username].strip
          @user.mobile = params[:mobile].strip
          if @user.valid?
            @user.save
            render json: { status: 1, message: "ok" }
          else
            render json: { status: 0, message: @user.errors.full_messages.to_sentence } 
          end
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
end