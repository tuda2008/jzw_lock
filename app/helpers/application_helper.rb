module ApplicationHelper

  def check_mobile(mobile)
    return false if mobile.length != 11
    !mobile.match(/^1[3|4|5|6|7|8|9][0-9]\d{4,8}$/).nil?
  end

  def get_wechat_mobile(session_key, iv, encrypted_data)
    encrypted_data = Base64.decode64(encrypted_data)
    iv = Base64.decode64(iv)
    session_key = Base64.decode64(session_key)

    cipher = OpenSSL::Cipher.new("AES-128-CBC")
    cipher.decrypt
    cipher.key = session_key
    cipher.iv =iv
    result = cipher.update(encrypted_data) + cipher.final
    begin
      JSON.parse(result)["purePhoneNumber"]
    rescue => e
      p e.message
      ""
    end
  end

  def send_sms(api_key, tpl_id, mobile, sms_code, error_msg, log)
    url = "https://sms.yunpian.com/v2/sms/tpl_single_send.json"
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
            #发送失败，更新每分钟发送限制
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