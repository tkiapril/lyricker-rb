#!/usr/bin/env ruby
require 'open-uri'
require 'net/http'
require 'net/https'
require 'json'
require 'sinatra'


set :bind, '0.0.0.0'

jakotable = {'ぁ' => '아', 'あ' => '아', 'ぃ' => '이', 'い' => '이', 'ぅ' => '우', 'う' => '우', 'ぇ' => '에', 'え' => '에', 'ぉ' => '오', 'お' => '오', 'か' => '카', 'が' => '가', 'き' => '키', 'ぎ' => '기', 'く' => '쿠', 'ぐ' => '구', 'け' => '케', 'げ' => '게', 'こ' => '코', 'ご' => '고', 'さ' => '사', 'ざ' => '자', 'し' => '시', 'じ' => '지', 'す' => '스', 'ず' => '즈', 'せ' => '세', 'ぜ' => '제', 'そ' => '소', 'ぞ' => '조', 'た' => '타', 'だ' => '다', 'ち' => '치', 'ぢ' => '지', 'っ' => 'ㅅ', 'つ' => '츠', 'づ' => '즈', 'て' => '테', 'で' => '데', 'と' => '토', 'ど' => '도', 'な' => '나', 'に' => '니', 'ぬ' => '누', 'ね' => '네', 'の' => '노', 'は' => '하', 'ば' => '바', 'ぱ' => '파', 'ひ' => '히', 'び' => '비', 'ぴ' => '피', 'ふ' => '후', 'ぶ' => '부', 'ぷ' => '푸', 'へ' => '헤', 'べ' => '베', 'ぺ' => '페', 'ほ' => '호', 'ぼ' => '보', 'ぽ' => '포', 'ま' => '마', 'み' => '미', 'む' => '무', 'め' => '메', 'も' => '모', 'ゃ' => '야', 'や' => '야', 'ゅ' => '유', 'ゆ' => '유', 'ょ' => '요', 'よ' => '요', 'ら' => '라', 'り' => '리', 'る' => '루', 'れ' => '레', 'ろ' => '로', 'ゎ' => '와', 'わ' => '와', 'ゐ' => '위', 'ゑ' => '우', 'を' => '오', 'ん' => '응', '　' => ' '}

get '/' do
	%{<html>
<head>
<title>일본어 노래 가사 자동 번역기</title>
</head>
<body>
<form action="/" method="post">
<input type="submit" value="이 가사를 번역 (시간이 좀 걸립니다)">
<br />
<textarea name="lyrics" rows="40" cols="80">
<textarea />
<br />
<input type="submit" value="이 가사를 번역 (시간이 좀 걸립니다)">
</form>
</body>
	</html>}
end

get '/robots.txt' do
	content_type :text
	%{User-agent: *
Disallow: /}
end

post '/' do
	translated = ''
	params[:lyrics].chomp.lines.map(&:chomp).each do |line|
		if not line.empty?
			translated << line << "\n"
			yomi = yomitan(line)
			yomi.chars.each do |char|
				if jakotable.include? char
					translated << jakotable[char]
				else
					translated << char
				end
			end
			translated << "\n"
			translated << translate_ntranstalk(:j2k, line, '1', '1') << "\n"
		else
			translated << "\n"
		end
		translated << "\n"
	end

	result = %{<html>
<head>
<title>일본어 노래 가사 자동 번역기</title>
</head>
<body>
	<div>}
	translated.chomp.lines.each do |line|
		result << line << '<br />'
	end
	result << %{</div>
</body>
	</html>}
	result
end

def translate_ntranstalk(dir, query, highlight, hurigana)
	uri = URI.parse("http://jpdic.naver.com/transProxy.nhn")
	https = Net::HTTP.new(uri.host,uri.port)
	https.use_ssl = false
	req = Net::HTTP::Post.new(uri.request_uri)
	req.initialize_http_header({
	                             'Accept' => '*/*',
	                             'Accept-Encoding' => 'gzip,deflate,sdch',
	                             'Accept-Language' => 'en-US,en;q=0.8',
	                             'Cache-Control' => 'max-age=0',
	                             'charset' => 'utf-8',
	                             'DNT' => '1',
	                             'Origin' => 'http://jpdic.naver.com',
	                             'X-Requested-With' => 'XMLHttpRequest',
	                             'Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8',
	                             'Host' => 'jpdic.naver.com',
	                             'IfModifiedSince' => 'Thu, 1 Jan 1970 00:00:00 GMT',
	                             'Referer' => 'http://jpdic.naver.com/trans.nhn',
	                             'User-Agent' => 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36'
	                         })
	req.set_form_data(
	  'dir' => dir.to_s,
	  'query' => query,
	  'highlight' => highlight.to_s,
		  'hurigana' => hurigana.to_s,
	)
	res = https.request(req)
	return JSON.parse(res.body)["resultData"]
end

def yomitan(str)
	open("http://yomi-tan.jp/api/yomi.php?ic=UTF-8&oc=UTF-8&k=h&n=1&t=#{ URI::encode str }", 'r:UTF-8') do |yomitan|
        yomitan.read
    end
end

