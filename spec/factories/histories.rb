# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :history, :class => 'Histories' do
    amount 1.5
    date "2014-11-07 10:21:12"
    balance 1.5
    user_id 1
  end
end
