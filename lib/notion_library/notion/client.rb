module Notion
  class Client
    def initialize
      Dotenv.load
      @notion_secret = ENV["NOTION_SECRET"]
      @notion_database_id = ENV["NOTION_DATABASE_ID"]
    end

    def register_book(book)
      notion_endpoint = URI.parse("https://api.notion.com/v1/pages")
      body = {
        "parent" => { "database_id" => @notion_database_id },
        "cover" => {
          "external" => {
            "url": book["largeImageUrl"]
          }
        },
        "properties" => {
          "Title": {
            "title": [
              {
                "text": {
                  "content": book["title"]
                }
              }
            ]
          },
          "Author": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": book["author"]
                }
              }
            ]
          },
          "Publisher": {
            "rich_text": [
              {
                "type": "text",
                "text": {
                  "content": book["publisherName"]
                }
              }
            ]
          },
          "ISBN": {
            "number": book["isbn"].to_i
          }
        }
      }.to_json
      begin
        response = Net::HTTP.post(notion_endpoint, body, headers)
      rescue StandardError => e
        puts e
      end
      response
    end

    def register_highlights(asin, highlights)
      notion_endpoint = URI.parse("https://api.notion.com/v1/databases/#{@notion_database_id}/query")
      body = {
        "filter": {
          "property": "ASIN",
          "rich_text": {
            "equals": asin
          }
        }
      }.to_json
      response = Net::HTTP.post(notion_endpoint, body, headers)
      page_id = JSON.parse(response.body)["results"][0]["id"]

      notion_endpoint = URI.parse("https://api.notion.com/v1/blocks/#{page_id}/children")
      blocks = []
      highlights.each do |highlight|
        blocks << text_block(highlight[:location])
        blocks << quote_block(highlight[:text])
        blocks << divider_block
      end
      body = { "children": blocks }.to_json
      http = Net::HTTP.new(notion_endpoint.host, notion_endpoint.port)
      http.use_ssl = true
      request = Net::HTTP::Patch.new(notion_endpoint, headers)
      request.body = body
      response = http.request(request)
    end

    private

    def headers
      {
        "Authorization" => "Bearer #{@notion_secret}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
    end

    def text_block(location)
      {
        "object": "block",
        "type": "paragraph",
        "paragraph": {
          "rich_text": [
            {
              "type": "text",
              "text": {
                "content": "Page.#{location}"
              }
            }
          ]
        }
      }
    end

    def quote_block(text)
      {
        "object": "block",
        "type": "quote",
        "quote": {
          "rich_text": [
            {
              "type": "text",
              "text": {
                "content": "#{text}",
              }
            }
          ]
        }
      }
    end

    def divider_block
      {
        "object": "block",
        "type": "divider",
        "divider": {}
      }
    end
  end
end
