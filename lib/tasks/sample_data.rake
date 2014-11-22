namespace :db do
  desc "Fill database with sample data"
  task populate: :environment do
    User.create!(name: "Admin",
                 email: "admin@gg.com",
                 password: "000000",
                 password_confirmation: "000000",
                 admin: true)
    User.create!(name: "Shawn",
                 email: "ss@gg.com",
                 password: "000000",
                 password_confirmation: "000000")
    User.create!(name: "Jack",
                 email: "jj@gg.com",
                 password: "000000",
                 password_confirmation: "000000")
    User.create!(name: "Karl",
                 email: "kk@gg.com",
                 password: "000000",
                 password_confirmation: "000000")    
    User.create!(name: "Mary",
                 email: "mm@gg.com",
                 password: "000000",
                 password_confirmation: "000000")
    # 99.times do |n|
    #   name  = Faker::Name.name
    #   email = "example-#{n+1}@railstutorial.org"
    #   password  = "password"
    #   User.create!(name: name,
    #                email: email,
    #                password: password,
    #                password_confirmation: password)
    # end
  end
end