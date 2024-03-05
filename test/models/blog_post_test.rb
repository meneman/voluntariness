require "test_helper"

class BlogPostTest < ActiveSupport::TestCase
  test "draft? returns true for drafted blug post" do
    assert blog_posts(:draft).draft?
  end

  test "draft? returns true for published blug post" do
    refute  blog_posts(:published).draft?
  end

  test "draft? returns true for scheduled blug post" do
    refute  blog_posts(:scheduled).draft?
  end
  test "published? returns true for published blog post" do
    assert  blog_posts(:published).published?
  end

  test "published? returns false for drafted blog post" do
    refute blog_posts(:draft).published?
  end
  
  test "published? returns false for scheduled blog post" do
    refute  blog_posts(:scheduled).published?
  end
  test "scheduled? returns true for scheduled blog post" do
    assert  blog_posts(:scheduled).scheduled?
  end
  test "scheduled? returns false for drafted blog post" do
    refute blog_posts(:draft).scheduled?
  end
  test "scheduled? returns false for published blog post" do
    refute  blog_posts(:published).scheduled?
  end



end

