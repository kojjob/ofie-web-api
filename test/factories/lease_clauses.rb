FactoryBot.define do
  factory :lease_clause do
    category { "general" }
    jurisdiction { "San Francisco" }
    clause_text { "Standard lease clause text goes here." }
    required { false }
    variables { {} }
  end
end
