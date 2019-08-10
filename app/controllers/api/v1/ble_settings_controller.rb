class Api::V1::BleSettingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :find_user, only: [:show, :create, :destroy]
  before_action :find_device, only: [:show, :create, :destroy]
  
  def show
    @ble_setting = BleSetting.where(user_id: @user.id, device_id: @device.id).first
    respond_to do |format|
      format.json do
        if @ble_setting
          data = { id: @ble_setting.id, ble_type: @ble_setting.ble_type, 
                   cycle: @ble_setting.cycle.nil? ? [] : @ble_setting.cycle,
                   cycle_start_at: @ble_setting.cycle_start_at.nil? ? "" : @ble_setting.cycle_start_at,
                   cycle_end_at: @ble_setting.cycle_end_at.nil? ? "" : @ble_setting.cycle_end_at,
                   start_at: @ble_setting.start_at.nil? ? "" : @ble_setting.start_at.strftime('%Y-%m-%d %H:%M:%S'),
                   end_at: @ble_setting.end_at.nil? ? "" : @ble_setting.end_at.strftime('%Y-%m-%d %H:%M:%S')
                  }
          render json: { status: 1, message: "ok", data: data }
        else
          render json: { status: 0, message: "ok" }
        end
      end
    end
  end

  def create
    @ble_setting = BleSetting.where(user_id: @user.id, device_id: @device.id).first
    respond_to do |format|
      format.json do
        if @ble_setting
          if params[:ble_type].to_i == BleSetting::TYPES[:cycle]
            data = { ble_type: params[:ble_type].to_i, cycle: params[:cycle].blank? ? [] : params[:cycle].split(",").map(&:to_i),
                     cycle_start_at: params[:cycle_start_at].blank? ? nil :  params[:cycle_start_at],
                     cycle_end_at: params[:cycle_end_at].blank? ? nil :  params[:cycle_end_at],
                     start_at: nil,
                     end_at: nil
                   }
          elsif params[:ble_type].to_i == BleSetting::TYPES[:duration]
            data = { ble_type: params[:ble_type].to_i, cycle: nil,
                     cycle_start_at: nil,
                     cycle_end_at: nil,
                     start_at: params[:start_at],
                     end_at: params[:end_at]
                   }
          elsif params[:ble_type].to_i == BleSetting::TYPES[:forever]
            data = { ble_type: params[:ble_type].to_i, cycle: nil,
                     cycle_start_at: nil,
                     cycle_end_at: nil,
                     start_at: nil,
                     end_at: nil
                   }
          end
          @ble_setting.update_attributes(data)
          render json: { status: 1, message: "ok", data: {} } 
        else
          @ble_setting = BleSetting.new(user_id: @user.id, device_id: @device.id, ble_type: params[:ble_type].to_i)
          if params[:ble_type].to_i == BleSetting::TYPES[:cycle]
            @ble_setting.cycle = params[:cycle].split(",").map(&:to_i)
            @ble_setting.cycle_start_at = params[:cycle_start_at]
            @ble_setting.cycle_end_at = params[:cycle_end_at]
          elsif params[:ble_type].to_i == BleSetting::TYPES[:duration]
          	@ble_setting.start_at = params[:start_at]
            @ble_setting.end_at = params[:end_at]
          end
          if @ble_setting.valid?
            @ble_setting.save
            render json: { status: 1, message: "ok", data: {} }
          else
            render json: { status: 0, message: @ble_setting.errors.full_messages.to_sentence } 
          end
        end
      end
    end
  end

  def destroy
    @ble_setting = BleSetting.where(user_id: @user.id, device_id: @device.id).first
    respond_to do |format|
      format.json do
        if @ble_setting
          @ble_setting.destroy
          render json: { status: 1, message: "ok", data: {} } 
        else
          render json: { status: 0, message: "没有找到蓝牙设置" }
        end
      end
    end
  end
 
  private
    def find_user
      @user = User.find_by(id: params[:user_id])
    end

    def find_device
      @device = Device.joins(:user_devices).where(:user_devices => { user_id: @user.id }, :devices => { id: params[:device_id] }).first
    end
end