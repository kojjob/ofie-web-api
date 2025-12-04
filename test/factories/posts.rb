FactoryBot.define do
  factory :post do
    title { "MyString" }
    slug { "MyString" }
    content { "MyText" }
    excerpt { "MyText" }
    author { nil }
    category { "MyString" }
    tags { "MyText" }
    published { false }
    published_at { "2025-10-02 02:06:45" }
    views_count { 1 }
  end
end
