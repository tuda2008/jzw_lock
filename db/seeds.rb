# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
AdminUser.create!(email: 'admin@example.com', password: 'password', password_confirmation: 'password') if Rails.env.development?
#User.create!(nickname: "hehe", mobile: "13800000000", gender: 1) if Rails.env.development?
#Device.create!(uuid: "d5a6", mac: "lock-a6-0C95415C4023", token: "d5a64cd81e5135532cc7fd31dd0c177c", status_id: 2) if Rails.env.development?