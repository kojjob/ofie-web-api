class Post < ApplicationRecord
  belongs_to :author, class_name: 'User'
  has_one_attached :featured_image
  has_rich_text :content

  # Multiple attachments for media gallery (images, videos, PDFs, audio)
  has_many_attached :media_attachments

  # Validations
  validates :title, presence: true, length: { maximum: 200 }
  validates :slug, presence: true, uniqueness: true
  validates :excerpt, length: { maximum: 500 }
  validates :category, presence: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? }
  before_create :set_published_at, if: :published?

  # Scopes
  scope :published, -> { where(published: true).where('published_at <= ?', Time.current) }
  scope :draft, -> { where(published: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(published_at: :desc) }
  scope :popular, -> { order(views_count: :desc) }

  # Instance methods
  def tags_array
    tags.to_s.split(',').map(&:strip)
  end

  def tags_array=(array)
    self.tags = array.join(', ')
  end

  def increment_views!
    increment!(:views_count)
  end

  def reading_time
    words_per_minute = 200
    word_count = content.to_plain_text.split.size
    (word_count / words_per_minute.to_f).ceil
  end

  # Media helper methods
  def images
    media_attachments.select { |attachment| attachment.content_type&.start_with?('image/') }
  end

  def videos
    media_attachments.select { |attachment| attachment.content_type&.start_with?('video/') }
  end

  def pdfs
    media_attachments.select { |attachment| attachment.content_type == 'application/pdf' }
  end

  def audio_files
    media_attachments.select { |attachment| attachment.content_type&.start_with?('audio/') }
  end

  def other_files
    media_attachments.reject do |attachment|
      attachment.content_type&.start_with?('image/', 'video/', 'audio/') ||
      attachment.content_type == 'application/pdf'
    end
  end

  private

  def generate_slug
    self.slug = title.to_s.parameterize
  end

  def set_published_at
    self.published_at ||= Time.current
  end
end
