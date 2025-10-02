class BlogController < ApplicationController
  before_action :authenticate_request, except: [:index, :show]
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :authorize_author!, only: [:edit, :update, :destroy]

  def index
    @posts = Post.published.recent.includes(:author, featured_image_attachment: :blob)

    # Filter by category if provided
    @posts = @posts.by_category(params[:category]) if params[:category].present?

    # Search functionality
    if params[:search].present?
      @posts = @posts.where("title ILIKE ? OR excerpt ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end

    @posts = @posts.page(params[:page]).per(9)
    @categories = Post.published.distinct.pluck(:category).compact.sort
  end

  def show
    @post.increment_views!
    @related_posts = Post.published
                        .where(category: @post.category)
                        .where.not(id: @post.id)
                        .recent
                        .limit(3)
  end

  def new
    @post = current_user.posts.build
  end

  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      redirect_to blog_post_path(@post.slug), notice: 'Post was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    # Handle media attachment removals BEFORE updating
    if params[:post] && params[:post][:remove_media_ids].present?
      params[:post][:remove_media_ids].reject(&:blank?).each do |attachment_id|
        attachment = @post.media_attachments.find_by(id: attachment_id)
        attachment&.purge
      end
      # Remove the remove_media_ids from params to avoid issues
      params[:post].delete(:remove_media_ids)
    end

    if @post.update(post_params)
      redirect_to blog_post_path(@post.slug), notice: 'Post was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to blog_index_path, notice: 'Post was successfully deleted.'
  end

  private

  def set_post
    @post = Post.find_by!(slug: params[:slug])
  end

  def authorize_author!
    redirect_to blog_index_path, alert: 'Not authorized' unless @post.author == current_user || current_user.landlord?
  end

  def post_params
    params.require(:post).permit(
      :title, :slug, :excerpt, :category, :tags,
      :published, :published_at, :featured_image, :content,
      media_attachments: []
    )
  end
end
