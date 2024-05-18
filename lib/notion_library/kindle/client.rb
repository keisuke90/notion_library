require 'nokogiri'

module Kindle
  class Client
    attr_accessor :email, :password, :url

    def initialize
      Dotenv.load
      @email = ENV["AMAZON_EMAIL"]
      @password = ENV["AMAZON_PASSWORD"]
      @url = 'https://read.amazon.co.jp/notebook'
    end

    def books
      @books ||= fetch_books
    end
  end
end