require 'mechanize'

module Kindle
  class Client
    class AuthenticationError < StandardError; end
    class CaptchaError < StandardError; end

    attr_accessor :email, :password, :url, :logged_in

    def initialize
      Dotenv.load
      @email = ENV["AMAZON_EMAIL"]
      @password = ENV["AMAZON_PASSWORD"]
      @url = 'https://read.amazon.co.jp/notebook'
      @logged_in = false
    end

    def books
      @books ||= fetch_books
    end

    def login
      signin_page = mechanize_client.get(url)
      form = signin_page.form("signIn")
      form.email = email
      form.password = password
      res = mechanize_client.submit(form)

      if res.search("#auth-captcha-image").any?
        resolution_url = res.link_with(text: /See a new challenge/).resolved_uri.to_s
        raise CaptchaError, "Received a CAPTCHA while attempting to sign in to your Amazon account. You will need to resolve this manually at #{resolution_url}"
      elsif res.search("#message_error > p").any?
        amazon_error = res.search("#message_error > p").children.first.to_s.strip
        raise AuthenticationError, "Unable to sign in, received error: '#{amazon_error}'"
      else
        @logged_in = true
      end
    end

    def mechanize_client
      @mechanize_client ||= initialize_mechanize_client
    end

    def initialize_mechanize_client
      mechanize_client = Mechanize.new
      mechanize_client.user_agent_alias = 'Mac Safari'
      mechanize_client
    end
  end
end