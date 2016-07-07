class User < ActiveRecord::Base
  #validates_format_of :twitter_username, without: /\W/, allow_blank: true
# validates_presence_of :twitter_username, if: :on_social_step?
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
         
         
end
