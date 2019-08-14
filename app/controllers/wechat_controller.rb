class WechatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def check_token
    render plain: params[:echostr]
  end

  def airkiss
    @wechat_app_id = ""
    wechat_app_secret = ""
    url = ""
    begin
      response = RestClient.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{@wechat_app_id}&secret=#{wechat_app_secret}", timeout: 2)
      token = JSON.parse(response.body)["access_token"]
      response = RestClient.get("https://api.weixin.qq.com/cgi-bin/ticket/getticket?access_token=#{token}&type=jsapi")
      ticket =  JSON.parse(response.body)['ticket']
      @timestamp = Time.now.to_i
      @uuid = Digest::MD5.hexdigest("#{@timestamp}" + Device::SALT)
      params_string = "jsapi_ticket=#{ticket}&noncestr=#{uuid}&timestamp=#{timestamp}&url=#{url}"
      @signature = Digest::SHA1.hexdigest(params_string)
    rescue => e
      p e.message
    end
  end
end