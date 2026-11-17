require 'net/http'
require 'uri'
require 'sqlite3'

BILL_ID = '3218'

URL = (
  'https://www.parliament.nsw.gov.au/' \
  'parliamentary-business/bills/' \
  "bill-details?billId=#{BILL_ID}"
)

KNOWN_TITLE = (
  'Gaming Machines Amendment ' \
  '(Centralised Monitoring System) Bill 2015'
)

uri = URI.parse(URL)

status = 0
body = ''

begin
  http = Net::HTTP.new(
    uri.host,
    uri.port
  )

  http.use_ssl = true

  request = Net::HTTP::Get.new(
    uri.request_uri
  )

  request['User-Agent'] = (
    'Mozilla/5.0 ' \
    'NSW-Parliament-Bill-Catalogue/1.0'
  )

  response = http.request(request)

  status = response.code.to_i
  body = response.body.to_s

rescue => error
  body = error.to_s
end

challenge = (
  body.include?('Just a moment') ||
  body.include?('cf-mitigated')
)

title_found = (
  body.downcase.include?(
    KNOWN_TITLE.downcase
  )
)

db = SQLite3::Database.new(
  'data.sqlite'
)

db.execute <<~SQL
  CREATE TABLE IF NOT EXISTS data (
    bill_id TEXT PRIMARY KEY,
    url TEXT,
    http_status INTEGER,
    response_size INTEGER,
    cloudflare_challenge INTEGER,
    title_found INTEGER,
    sample TEXT
  )
SQL

db.execute(
  <<~SQL,
    INSERT OR REPLACE INTO data (
      bill_id,
      url,
      http_status,
      response_size,
      cloudflare_challenge,
      title_found,
      sample
    )
    VALUES (?, ?, ?, ?, ?, ?, ?)
  SQL
  [
    BILL_ID,
    URL,
    status,
    body.bytesize,
    challenge ? 1 : 0,
    title_found ? 1 : 0,
    body[0, 2000]
  ]
)

db.close

puts "Bill ID: #{BILL_ID}"
puts "HTTP: #{status}"
puts "Size: #{body.bytesize}"
puts "Cloudflare challenge: #{challenge}"
puts "Known title found: #{title_found}"
