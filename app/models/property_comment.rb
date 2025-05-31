class PropertyComment < ApplicationRecord
  belongs_to :user
  belongs_to :property
  belongs_to :parent, class_name: "PropertyComment", optional: true
  
  has_many :replies, class_name: "PropertyComment", foreign_key: "parent_id", dependent: :destroy
  has_many :comment_likes, dependent: :destroy
  has_many :liked_by_users, through: :comment_likes, source: :user

  validates :content, presence: true, length: { minimum: 1, maximum: 2000 }
  validate :parent_cannot_be_reply, if: :parent_id?
  validate :parent_must_belong_to_same_property, if: :parent_id?

  scope :top_level, -> { where(parent_id: nil) }
  scope :replies, -> { where.not(parent_id: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :most_liked, -> { order(likes_count: :desc) }
  scope :not_flagged, -> { where(flagged: false) }
  scope :flagged, -> { where(flagged: true) }
  scope :for_property, ->(property) { where(property: property) }
  scope :for_user, ->(user) { where(user: user) }

  # Instance methods
  def reply?
    parent_id.present?
  end

  def top_level?
    parent_id.nil?
  end

  def liked_by?(user)
    return false unless user
    comment_likes.exists?(user: user)
  end

  def toggle_like!(user)
    return false unless user
    
    existing_like = comment_likes.find_by(user: user)
    if existing_like
      existing_like.destroy!
      decrement!(:likes_count)
      false # unliked
    else
      comment_likes.create!(user: user)
      increment!(:likes_count)
      true # liked
    end
  end

  def flag!(reason = nil, flagged_by_user = nil)
    update!(
      flagged: true,
      flagged_reason: reason,
      flagged_at: Time.current
    )
    
    # Create notification for property owner and admins
    create_flag_notification(flagged_by_user) if flagged_by_user
  end

  def unflag!
    update!(
      flagged: false,
      flagged_reason: nil,
      flagged_at: nil
    )
  end

  def mark_as_edited!
    update!(
      edited: true,
      edited_at: Time.current
    )
  end

  def can_be_edited_by?(user)
    return false unless user
    user == self.user && created_at > 15.minutes.ago
  end

  def can_be_deleted_by?(user)
    return false unless user
    user == self.user || user == property.user || user.admin?
  end

  def display_content
    if flagged?
      "[This comment has been flagged and is under review]"
    else
      content
    end
  end

  # Class methods
  def self.recent_for_property(property, limit = 10)
    where(property: property)
      .not_flagged
      .includes(:user, :replies)
      .top_level
      .recent
      .limit(limit)
  end

  def self.with_replies_for_property(property)
    where(property: property)
      .not_flagged
      .includes(:user, replies: :user)
      .top_level
      .recent
  end

  private

  def parent_cannot_be_reply
    if parent&.reply?
      errors.add(:parent, "cannot be a reply to another reply")
    end
  end

  def parent_must_belong_to_same_property
    if parent && parent.property_id != property_id
      errors.add(:parent, "must belong to the same property")
    end
  end

  def create_flag_notification(flagged_by_user)
    # Notify property owner
    if property.user != flagged_by_user
      Notification.create!(
        user: property.user,
        title: "Comment Flagged",
        message: "A comment on your property '#{property.title}' has been flagged for review.",
        notification_type: "comment_flagged",
        notifiable: self
      )
    end

    # Notify admins (if you have admin users)
    # User.admin.each do |admin|
    #   Notification.create!(
    #     user: admin,
    #     title: "Comment Flagged",
    #     message: "A comment has been flagged and requires review.",
    #     notification_type: "comment_flagged",
    #     notifiable: self
    #   )
    # end
  end
end
