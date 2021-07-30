---
layout: post
title: RSpec list of subjects
---

- basic set-up ✅
- lexicon ✅
- model tests: validations, methods class + instance
- controllers tests
- apis tests
- mock instances
- mock requests
- before do
- oneliners
- shared_examples
- factories: nested factory + trait
- RSpec commands: rspec, rspec --next-failure, -e, file:number_of_line
- factory girl
- when to instanciate / create?
- shared context within a test suite

shared_context 'with an audio book file' do
    let(:book_file) { create :book_file, mimetype: :audio_mp3, quality: quality }
    let(:quality) { :high }

    let(:bucket_directory) { "books/#{book_file.book_id / 1_000}/#{book_file.book_id}" }
    let(:s3_client) do
      Aws::S3::Client.new(
        stub_responses: {
          list_objects_v2: [
            {
              prefix: "#{bucket_directory}/audio/uncrypted/mp3/#{quality}",
              contents: [
                { key: "#{bucket_directory}/audio/uncrypted/mp3/#{quality}/file_0_1.mp3" }
              ]
            },
            {
              prefix: "#{bucket_directory}/audio/crypted/mp3/#{quality}",
              contents: [
                { key: "#{bucket_directory}/audio/crypted/mp3/#{quality}/file_0_1.mp3" }
              ]
            }
          ]
        }
      )
    end
  end

  include_context 'with an audio book file'



## The basic stuff

- subject + named subject
- let + let!
- context + describe
- it '' do end
- expect (put onliner in another post)

## RSpec documentation

It's fricking hard to read. Don't.
