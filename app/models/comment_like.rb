class CommentLike < ApplicationRecord
  belongs_to :user
  belongs_to :property_comment

  validates :user_id, uniqueness: { scope: :property_comment_id }

  # Callbacks
  after_create :increment_comment_likes_count
  after_destroy :decrement_comment_likes_count

  private

  def increment_comment_likes_count
    property_comment.increment!(:likes_count)
  end

  def decrement_comment_likes_count
    property_comment.decrement!(:likes_count)
  end
end
