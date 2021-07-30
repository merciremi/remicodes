---
layout: post
title: 'RSpec fundamentals: test your models'
---

Testing models with RSpec is one of the go-to strategies when testing your application. Here, I want to share an essay without _a priori_ about [what tests are considered useful](https://getaround.tech/non-deterministic-testing/){:target="\_blank"} and [those which are not](https://www.codewithjason.com/different-kinds-rails-tests-use/){:target="\_blank"}.
. We'll see all of the things we can test in our models.

We'll get to know basic testing with RSPec built-in features and use neat tool called [shoulda matchers](https://github.com/thoughtbot/shoulda-matchers#activemodel-matchers){:target="\_blank"}.

## Let's draw up a model

{% highlight ruby %}
  # app/models/user.rb
  class User < ActiveRecord::Base
    enum gender: { gender_neutral: 0, non_binary: 1, male: 2, female: 3, other: 4 }

    has_many :posts

    validates :gender, inclusion: { in: genders.keys }

    scope :by_gender, ->(gender) { where(gender: gender) }

    def full_name
      "#{formatted_first_name}" #{formatted_last_name}"
    end

    private

    def formatted_first_name
      first_name.capitalize
    end

    def formatted_last_name
      first_name.capitalize
    end
  end
{% endhighlight %}

We can notice several elements we'll need to test:
- an enum
- an association
- a validation
- a scope (that will also serve as our example for class methods)
- a public method
- two private methods

## Enum
## Validations
## Scope and class methods
## Public methods
## Private methods

## validations

with shoulda matcher
describe 'Validations' do
  subject { build(:like) }

  it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(%i[likeable_id likeable_type]) }
end

without
describe '#valid?' do
    subject { book_file.valid? }

    let(:book_file) { build :book_file }

    it { is_expected.to be true }

    context 'when book is missing' do
      before { book_file.book = nil }

      it { is_expected.to be false }
    end
end


---

## callbacks
## class methods and scopes

'.class_method'

class Pizza and find all pizzas with cheese

subject(:with_cheese) { described_class.with_cheese }

## instance methods

'#instance_method'


## dependency injection: enqued jobs, services... everything that needs a mock => how do i treat that?
