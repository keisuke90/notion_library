require 'mechanize'

module Kindle
  class Client
    class AuthenticationError < StandardError; end
    class CaptchaError < StandardError; end

    attr_accessor :email, :password, :url, :logged_in, :logged_in_page

    def initialize
      Dotenv.load
      @email = ENV["AMAZON_EMAIL"]
      @password = ENV["AMAZON_PASSWORD"]
      @url = 'https://read.amazon.co.jp/notebook'
      @logged_in = false
      @logged_in_page = nil
    end

    def get_highlights(asin)
      login unless @logged_in
      mechanize_client.get("#{@url}?captcha_verified=1&asin=#{asin}&contentLimitState=&")
                      .search("div#kp-notebook-annotations")
                      .children
                      .select { |child| child.name == "div" }
                      .select { |child| child.children.search("div.kp-notebook-highlight").first }
                      .map    { |html_elements| {
                        location: html_elements.search("input#kp-annotation-location").first.attributes["value"].value,
                        text: html_elements.children.search("div.kp-notebook-highlight").first.text
                      } }
    end

    def books
      @books ||= parse_books
    end

    def parse_books
      login unless @logged_in
      @logged_in_page.search("div#kp-notebook-library").children.map do |book|
        {
          asin: book.attributes["id"]&.value,
          title: book.children.search("h2")&.first&.text,
        }
      end.compact
    end

    def login
      signin_page = mechanize_client.get(url)
      form = signin_page.form("signIn")
      form.email = email
      form.password = password
      res = mechanize_client.submit(form)

      if res.search(".kp-notebook-title").any?
        @logged_in_page = res
        @logged_in = true
      else
        raise AuthenticationError, "ログインに失敗しました。"
      end
    rescue StandardError => e
      puts e.message
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
