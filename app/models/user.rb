# == Schema Information
#
# Table name: users
#
#  id           :bigint           not null, primary key
#  provider     :integer          default(1), not null
#  nickname     :string(255)
#  mobile       :string(255)
#  avatar_url   :string(255)
#  open_id      :string(255)
#  session_key  :string(255)
#  country      :string(255)
#  province     :string(255)
#  city         :string(255)
#  gender       :integer          not null
#  device_count :integer          default(0)
#  latitude     :string(30)       default("")
#  longitude    :string(30)       default("")
#  address      :string(120)      default("")
#  birthday     :date
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class User < ApplicationRecord
  YUNPIAN_API_KEY = ""
  PROVIDERS = { wechat: 1, qq: 2 }
  PROVIDER_COLLECTION = [["wechat", 1], ["qq", 2]]
  PROVIDER_HASH = { 1 => "wechat", 2 => "qq" }

  GENDERS = { "未知": 0, "男": 1, "女": 2 }
  GENDER_COLLECTION = [["未知", 0], ["男", 1], ["女", 2]]
  GENDER_HASH = { 0 => "未知", 1 => "男", 2 => "女" }

  has_many :user_devices, :dependent => :destroy
  has_many :devices, :through => :user_devices

  has_many :invitations, :dependent => :destroy
  has_many :user_invitors, :dependent => :destroy

  has_many :messages, :dependent => :destroy

  validates :mobile, :open_id, uniqueness: { case_sensitive: false }

  scope :male, -> { where(gender: 1) }
  scope :female, -> { where(gender: 2) }

  def name
    self.nickname
  end

  def self.token
    token = @weixin_token
    if token.nil?
      token = reload_token
    else
      token = reload_token if Time.now > @wx_token_expires_in
    end
    return token
  end

  def self.reload_token
    begin
      response = RestClient.get("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=#{ENV["WECHAT_APP_ID"]}&secret=#{ENV["WECHAT_APP_SECRET"]}", timeout: 2)
      @weixin_token = JSON.parse(response.body)["access_token"]
      @wx_token_expires_in = Time.now + JSON.load(response.body)["expires_in"]
    rescue => e
      p e.message
    end
    return @weixin_token
  end

  def self.send_msg(openid, content, type)
    body = type == "text" ? {
      touser: openid,
      msgtype: "#{type}",
      text:
      {
        content: content
      }} : content
    begin
      response = RestClient.post("https://api.weixin.qq.com/cgi-bin/message/custom/send?access_token=#{self.token}", body: JSON.generate(body), timeout: 2)
      result = JSON.parse(response.body)
    rescue => e
      p e.message
    end
  end

  def self.find_or_create_by_wechat(code)
    return nil unless code
    wechat_request_url = "https://api.weixin.qq.com/sns/jscode2session?appid=#{ENV["WECHAT_APP_ID"]}&secret=#{ENV["WECHAT_APP_SECRET"]}&js_code=#{code}&grant_type=authorization_code"
    begin
      response = RestClient.post(wechat_request_url, timeout: 2)
      open_id = JSON.load(response.body)["openid"]
      session_key = JSON.load(response.body)["session_key"]
    rescue => e
      p e.message
    end
    return nil unless open_id
    entity = self.find_by(open_id: open_id)
    unless entity
      entity = self.create(open_id: open_id, session_key: session_key, gender: 0)
    else
      entity.update_attribute(:session_key, session_key) if session_key
    end
    return entity
  end

  def self.users_by_device(device, user, page, per_page)
    User.select("users.id, users.nickname, users.mobile, users.avatar_url, 
      ble_settings.ble_type, ble_settings.cycle, ble_settings.start_at, ble_settings.end_at,
      ble_settings.cycle_start_at, ble_settings.cycle_end_at,
      user_devices.ownership, user_devices.finger_count, user_devices.password_count, 
      user_devices.card_count, user_devices.temp_pwd_count, user_devices.has_ble_setting")
    .joins(:user_devices)
    .joins("left join ble_settings on ble_settings.user_id=user_devices.user_id and ble_settings.device_id=user_devices.device_id")
    .where("user_devices.device_id=? and user_devices.visible=true and (user_devices.author_id=? or user_devices.user_id=?)", device.id, user.id, user.id)
    .order("user_devices.ownership desc").page(page).per(per_page)
  end
  
  def invitors
    User.joins("inner join user_invitors ui on ui.user_id=users.id inner join invitations it on it.id=ui.invitation_id")
    .select("distinct users.id, users.nickname, users.avatar_url")
    .where("it.user_id=?", self.id)
  end
end
