class WechatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_token
    wechat_app_id = ""
    wechat_app_secret = ""
    begin
      response = RestClient.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{wechat_app_id}&secret=#{wechat_app_secret}", timeout: 2)
      @weixin_token = JSON.parse(response.body)["access_token"]
      @wx_token_expires_in = Time.now + JSON.load(response.body)["expires_in"]
    rescue => e
      p e.message
    end
  end

  def check_token
    respond_to do |format|
      format.html { render :layout => false, :text => "hello" }
    end
  end

  def airkiss

  end
end