class Api::V1::InvitationsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user
  before_action :find_device, only: [:create]
  before_action :find_invitation_token, only: [:join_by_token]

  def create
  	invitation = Invitation.where(user_id: @user.id, device_id: @device.id, invitation_limit: Invitation::MAX_LIMIT).first
  	if invitation
  	  invitation.update_attribute(:invitation_expired_at, Time.now + Invitation::MAX_DAYS_EXPIRED * 24 * 60 * 60)
  	else
  	  invitation = Invitation.new(user_id: @user.id, device_id: @device.id)
  	  invitation.invitation_token = SecureRandom.hex[0..11] 
  	  invitation.invitation_expired_at = Time.now + Invitation::MAX_DAYS_EXPIRED * 24 * 60 * 60
  	  invitation.save if invitation.valid?
  	end
  	respond_to do |format|
      format.json do
        render json: { status: 1, message: "ok", data: {invitation_token: invitation.invitation_token} }
      end
    end
  end

  def join_by_token
  	respond_to do |format|
  	  format.json do
        if @invitation.nil?
          render json: { status: 0, message: "邀请码不存在" } and return
        else
    	  	if Time.now > @invitation.invitation_expired_at || @invitation.invitation_limit < 1
    	      render json: { status: 0, message: "邀请码已过期" } and return
    	    else
    	      device = @invitation.device
    	      user_device = UserDevice.where(user_id: @invitation.user_id, device_id: @invitation.device_id).first
    	      #if user_device.is_super_admin?
            #  if UserDevice.where(device_id: @invitation.device_id, :ownership => UserDevice::OWNERSHIP[:admin]).count < UserDevice::MAX_ADMIN_LIMIT
    	      #	  UserDevice.create(:user => @user, :device => device, :ownership => UserDevice::OWNERSHIP[:admin])
    	      #	else
    	      #	  UserDevice.create(:user => @user, :device => device, :ownership => UserDevice::OWNERSHIP[:user])
    	      #  end
    	      #else
    	      	UserDevice.create(:user => @user, :device => device, :ownership => UserDevice::OWNERSHIP[:user])
    	      #end
            ui = UserInvitor.new(:user_id => @user.id, :invitation_id => @invitation.id)
            ui.save if ui.valid?
            @invitation.update_attribute(:invitation_limit, @invitation.invitation_limit-1)
            WxMsgInvitationNotifierWorker.perform_in(10.seconds, device.all_admin_users.map(&:id), "#{@invitation.user.name} 邀请 #{@user.name} 加入了 #{device.name}", "text")
    	      render json: { status: 1, message: "ok", data: {id: device.id, name: device.name} }
    	    end
        end
  	  end
    end
  end

private
  def find_invitation_token
  	@invitation = Invitation.includes(:device).where(invitation_token: params[:invitation_token]).first
  end

  def find_user
  	@user = User.find_by(open_id: params[:openid])
  end

  def find_device
  	@device = Device.joins(:user_devices).where(:user_devices => { user_id: @user.id }, :devices => { id: params[:device_id] }).first
  end
end