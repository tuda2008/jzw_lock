class Api::V1::WechatController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user

  def update_form_ids

  end

  private
    def find_user
      @user = User.find_by(open_id: params[:openid])
    end
end