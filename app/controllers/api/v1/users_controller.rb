class Api::V1::UsersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user, only: [:update_wechat_userinfo, :update_gps, :info, :sms_verification_code]

  def wechat_auth
  	user = User.find_or_create_by_wechat(params[:code])
    respond_to do |format|
      format.json do
        if user
          render json: { status: 1, message: "ok", data: { openid: user.open_id, device_num: UserDevice.where(user_id: user.id).count } }
        else
          render json: { status: 0, message: "授权失败" }
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
      	  render json: { status: 1, message: "ok" }
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
              device_num: UserDevice.where(user_id: @user.id).count,
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
    unless check_mobile(params[:mobile])
      return { code: 1, message: "请输入有效的手机号", data: {} }
    end
    unless %W(1 2 3 4).include?(params[:type].to_s)
      return { code: 1, message: "type参数错误", data: {} }
    end

    # 检查手机是否符合获取验证码的要求
    type = params[:type].to_i
    user = User.find_by(mobile: params[:mobile])
    if type == 1    # 注册
      return { code: 1, message: "#{params[:mobile])}已经注册", data: {} } if user.present?
    elsif type == 4 # 绑定、修改手机号码
      return { code: 1, message: "#{params[:mobile])}已经被占用", data: {} } if user.present?
    else # 重置密码和修改密码
      return { code: 1, message: "#{params[:mobile]}未注册", data: {} } if user.blank?
    end

    # 1分钟内多次提交检测
    sym = "#{params[:mobile]}_#{params[:type]}".to_sym
    if session[sym] && ( Time.now.to_i - session[sym].to_i ) < 60 + rand(3)
      return { code: 1, message: "同一手机号1分钟内只能获取一次验证码，请稍后重试", data: {} }
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
          return { code: 1, message: "同一手机号24小时内只能获取5次验证码，请稍后再试", data: {} }
        end
      end
    end

    # 获取验证码并发送
    code = AuthCode.where('mobile = ? and verified = ? and auth_type = ?', params[:mobile], false, type).first
    code = AuthCode.create!(mobile: params[:mobile], auth_type: type) if code.blank?
  
    if code
      result = send_sms('todo', params[:mobile], code.code, "获取验证码失败")
      if result['code'].to_i == 103
        # 发送失败，更新每分钟发送限制
        session.delete(sym)
      end
      if result['code'].to_i == 0
        # 发送成功，更新发送日志
        log.update_attribute(:sms_total, log.sms_total + 1)
      end
      result
    else
      return { code: 1, message: "验证码生成错误，请重试", data: {} }
    end
  end

  def bind_mobile
    unless check_mobile(params[:mobile])
      return { code: 1, message: "请输入有效的手机号", data: {} }
    end
    unless %W(1 2 3 4).include?(params[:type].to_s)
      return { code: 1, message: "type参数错误", data: {} }
    end
    user = User.find_by(mobile: params[:mobile])
    if user.present?
      return { code: 1, message: "#{params[:mobile]}已被绑定", data: {} }
    end
    ac = AuthCode.where('mobile = ? and code = ? and verified = ?', params[:mobile], params[:verification_code], false).first
    if ac.blank?
      return { code: 1, message: "验证码无效", data: {} }
    else
      ac.update_attribute(:verified, true)
      @user.update_attribute(:mobile, params[:mobile])
      return { code: 0, message: "ok", data: {} }
    end
  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end

    def check_mobile(mobile)
      return false if mobile.length != 11
      mobile =~ /\A1[3|4|5|7|8][0-9]\d{4,8}\z/
    end

    def send_sms(api_key, mobile, sms_code, error_msg)
      url = "https://sms.yunpian.com/v2/sms/tpl_single_send.json"
      tpl_id = 1689800
      tpl_value = "#code#=#{sms_code}"
      options = "apikey=#{api_key}&mobile=#{mobile}&tpl_id=#{tpl_id}&tpl_value=#{tpl_value}"
      
      begin
        response = RestClient.post(url, options)
        result = JSON.parse(response.body)

        if result['code'] == 0
          return { code: 0, message: "ok" }
        else
          if result['code'] == 9 || result['code'] == 17
            return { code: 1, message: result['msg'] }
          else
            return { code: 1, message: result['msg'] }
          end
        end
      rescue => e
        p e.message
        return { code: 1, message: "发送失败，请稍后重试" }
      end
    end
end