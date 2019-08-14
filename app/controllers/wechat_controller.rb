class WechatController < ApplicationController
  skip_before_action :verify_authenticity_token

  def get_token
  	begin
      response = RestClient.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{WECHAT_APP_ID}&secret=#{WECHAT_APP_SECRET}", timeout: 2)
      @weixin_token = JSON.parse(response.body)["access_token"]
      @wx_token_expires_in = Time.now + JSON.load(response.body)["expires_in"]
    rescue => e
      p e.message
    end
  end

	def airkiss

	end
end