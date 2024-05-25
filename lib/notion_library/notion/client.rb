module Notion
  class Client
    ENDPOINT = {
      databases: "https://api.notion.com/v1/databases",
      pages: "https://api.notion.com/v1/pages",
      blocks: "https://api.notion.com/v1/blocks"
    }

    def initialize(secret, database_id)
      @notion_secret = secret
      @notion_database_id = database_id
    end

    def register_book(book)
      pages_endpoint = URI.parse(ENDPOINT[:pages])
      body = {
        "parent" => { "database_id" => @notion_database_id },
        "cover" => cover(book["largeImageUrl"]),
        "properties" => {
          "Title": title_property(book["title"]),
          "Author": text_property(book["author"]),
          "Publisher": text_property(book["publisherName"]),
          "ISBN": number_property(book["isbn"])
        }
      }.to_json
      Net::HTTP.post(pages_endpoint, body, headers)
    rescue StandardError => e
      puts e
    end

    def register_highlights(asin, highlights)
      page_id = fetch_page_id(asin)
      return unless page_id

      blocks = generate_blocks(highlights)
      update_page_blocks(page_id, blocks)
    end

    private

    def headers
      {
        "Authorization" => "Bearer #{@notion_secret}",
        "Content-Type" => "application/json",
        "Notion-Version" => "2022-06-28"
      }
    end

    def fetch_page_id(asin)
      url = URI.parse("#{ENDPOINT[:databases]}/#{@notion_database_id}/query")
      body = {
        "filter": {
          "property": "ASIN",
          "rich_text": {
            "equals": asin
          }
        }
      }.to_json
      response = Net::HTTP.post(url, body, headers)
      JSON.parse(response.body).dig("results", 0, "id")
    rescue StandardError => e
      puts e
    end

    def generate_blocks(highlights)
      highlights.flat_map do |highlight|
        [
          text_block(highlight[:location]),
          quote_block(highlight[:text]),
          divider_block
        ]
      end
    end

    def update_page_blocks(page_id, blocks)
      url = URI.parse("#{ENDPOINT[:blocks]}/#{page_id}/children")
      body = { "children": blocks }.to_json
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Patch.new(url, headers)
      request.body = body
      http.request(request)
    rescue StandardError => e
      puts e
    end

    def cover(url)
      {
        "external" => {
          "url": url
        }
      }
    end

    def title_property(title)
      {
        "title": [
          {
            "text": {
              "content": title
            }
          }
        ]
      }
    end

    def text_property(text)
      {
        "rich_text": [
          {
            "type": "text",
            "text": {
              "content": text
            }
          }
        ]
      }
    end

    def number_property(number)
      {
        "number": number.to_i
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
