
# frozen_string_literal: true

class AddManualExtraTimeToQuizzesInstance < ActiveRecord::Migration[7.0]
  def change
    add_column :quizzes_instances,
      :manual_extra_time,
      :integer,
      comment: "in seconds",
      default: 0,
      null: false
  end
end



change_column_comment(table_name, column_name, comment_or_changes)

Changes the comment for a column or removes it if nil.

Passing a hash containing :from and :to will make this change reversible in migration:

change_column_comment(:posts, :state, from: "old_comment", to: "new_comment")

https://devdocs.io/rails~7.0/activerecord/connectionadapters/schemastatements#method-i-change_column_comment
