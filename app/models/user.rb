class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_many :contracts, dependent: :destroy
  
  # バリデーション
  validates :name, presence: true, length: { maximum: 50 }

  # 退会フラグのチェック（is_activeがfalseならログイン不可）
  def active_for_authentication?
    super && is_active != false
  end

  # 退会済みアカウントのエラーメッセージ
  def inactive_message
    is_active == false ? :inactive_account : super
  end
end
