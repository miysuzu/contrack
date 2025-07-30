class Comment < ApplicationRecord
  belongs_to :contract
  belongs_to :commentable, polymorphic: true
  belongs_to :parent, class_name: 'Comment', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'parent_id', dependent: :destroy
  has_many :comment_notifications, dependent: :destroy
  
  # バリデーション
  validates :content, presence: true, length: { maximum: 1000 }
  validates :depth, numericality: { less_than_or_equal_to: 5, message: "返信の深さは5階層までです" }
  
  # コールバック
  before_create :set_depth
  before_validation :set_default_depth
  after_create :create_notifications
  
  # スコープ
  scope :top_level, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:created_at) }
  
  # 返信可能かチェック
  def can_reply?
    depth < 5
  end
  
  # トップレベルコメントかチェック
  def top_level?
    parent_id.nil?
  end
  
  # 返信かチェック
  def reply?
    !top_level?
  end
  
  # コメント作成者の名前を取得
  def author_name
    commentable.name
  end
  
  private
  
  def set_default_depth
    self.depth ||= 0
  end
  
  def set_depth
    if parent_id.present?
      self.depth = parent.depth + 1
    else
      self.depth = 0
    end
  end
  
  def create_notifications
    # 契約書の所有者に通知を作成（自分以外の場合）
    if contract.user.present? && !(commentable.is_a?(User) && commentable == contract.user)
      CommentNotification.create!(
        user: contract.user,
        admin: commentable.is_a?(Admin) ? commentable : nil,
        comment: self,
        read: false
      )
    end
    
    # 契約書の管理者に通知を作成（会員がコメントした場合、かつ管理者が自分以外の場合）
    if contract.admin.present? && commentable.is_a?(User) && contract.admin != commentable
      CommentNotification.create!(
        user: nil,
        admin: contract.admin,
        comment: self,
        read: false
      )
    end
    
    # 親コメントの作成者に通知を作成（返信の場合、かつ自分以外の場合）
    if parent.present? && parent.commentable != commentable
      if parent.commentable.is_a?(User) && parent.commentable != commentable
        CommentNotification.create!(
          user: parent.commentable,
          admin: commentable.is_a?(Admin) ? commentable : nil,
          comment: self,
          read: false
        )
      elsif parent.commentable.is_a?(Admin) && parent.commentable != commentable
        CommentNotification.create!(
          user: commentable.is_a?(User) ? commentable : nil,
          admin: parent.commentable,
          comment: self,
          read: false
        )
      end
    end
    
    # 管理者がコメントした場合の通知
    if commentable.is_a?(Admin)
      # 契約書の作成者（管理者）にも通知を作成（自分以外の場合）
      if contract.admin.present? && contract.admin != commentable
        CommentNotification.create!(
          user: nil,
          admin: contract.admin,
          comment: self,
          read: false
        )
      end
      
      # 同じ契約書にコメントした他の管理者に通知を作成（自分以外の場合）
      other_admins = contract.comments.where.not(commentable: commentable)
                             .where(commentable_type: 'Admin')
                             .distinct.pluck(:commentable_id)
      
      other_admins.each do |admin_id|
        # 自分自身には通知を作成しない
        next if admin_id == commentable.id
        
        CommentNotification.create!(
          user: nil,
          admin_id: admin_id,
          comment: self,
          read: false
        )
      end
    end
  end
end
