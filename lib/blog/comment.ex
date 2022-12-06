defmodule Blog.Comment do
  use Bee.Entity

  attribute :text, :text do
  end

  attribute :sentiment, :enum do
    one_of(:sentiment)
  end

  belongs_to(:post)
  belongs_to(:user)
  has_many(:votes)
end
