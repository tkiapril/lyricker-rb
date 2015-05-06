#!/usr/bin/env ruby
require 'open-uri'
require 'net/http'
require 'net/https'
require 'json'
require 'sinatra'


set :bind, '0.0.0.0'

# か゚  き゚  く゚  け゚  こ゚ not implemented

Kana_single = {
  'あ' => '아', 'い' => '이', 'う' => '우', 'え' => '에', 'お' => '오',
  'か' => '카', 'き' => '키', 'く' => '쿠', 'け' => '케', 'こ' => '코',
  'さ' => '사', 'し' => '시', 'す' => '스', 'せ' => '세', 'そ' => '소',
  'た' => '타', 'ち' => '치', 'つ' => '츠', 'て' => '테', 'と' => '토',
  'な' => '나', 'に' => '니', 'ぬ' => '누', 'ね' => '네', 'の' => '노',
  'は' => '하', 'ひ' => '히', 'ふ' => '후', 'へ' => '헤', 'ほ' => '호',
  'ま' => '마', 'み' => '미', 'む' => '무', 'め' => '메', 'も' => '모',
  'や' => '야', 'ゆ' => '유', 'よ' => '요',
  'ら' => '라', 'り' => '리', 'る' => '루', 'れ' => '레', 'ろ' => '로',
  'わ' => '와', 'ゐ' => '위', 'ゑ' => '에', 'を' => '오',

  'が' => '가', 'ぎ' => '기', 'ぐ' => '구', 'げ' => '게', 'ご' => '고',
  'ざ' => '자', 'じ' => '지', 'ず' => '즈', 'ぜ' => '제', 'ぞ' => '조',
  'だ' => '다', 'ぢ' => '지', 'づ' => '즈', 'で' => '데', 'ど' => '도',
  'ば' => '바', 'び' => '비', 'ぶ' => '부', 'べ' => '베', 'ぼ' => '보',

  'ぱ' => '파', 'ぴ' => '피', 'ぷ' => '푸', 'ぺ' => '페', 'ぽ' => '포',
}

Kana_before_yo_on = [
  '키',
  '시',
  '치',
  '니',
  '히',
  '미',
  '리',

  '기',
  '지',
  '비',

  '피',
]

Yo_on = {
  'ゃ' => 'ㅑ', 'ゅ' => 'ㅠ', 'ょ' => 'ㅛ',
}

Leftovers = {
  'ぁ' => '아', 'ぃ' => '이', 'ぅ' => '우', 'ぇ' => '에', 'ぉ' => '오',
  'ゎ' => '와'
}

Punctuation = {
  'ー' => '-', '！' => '!', '？' => '?', '“' => '"', '”' => '"', '　' => ' ', '、' => ',', '。' => '.'
}

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
</textarea>
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
  transcript = ""
  syllable = ""
  params[:lyrics].chomp.lines.map(&:chomp).each do |line|
    if not line.empty?
      transcript += line + "\n"

      if not line.match(/^[\x00-\x7F]+$/).nil?
        transcript += (line + "\n") * 2
      else
        yomi = yomitan(line)
        syllable = ""

        yomi.chars.each do |char|
          if Punctuation.include? char
            transcript += syllable + Punctuation[char]
            syllable = ""
          elsif syllable[-1] == 'ん'
            last_char = break_hangul(syllable[-2])
            transcript += syllable[0..-3]
            if Kana_single.include? char
              transcript += assemble_hangul(last_char[0], last_char[1], 'ㄴ')  # fix needed to distinguish n and m etc. sounds
              syllable = Kana_single[char]
            else
              transcript += assemble_hangul(last_char[0], last_char[1], 'ㅇ') + char  # default
              syllable = ""
            end
          elsif syllable.empty? or not break_hangul(syllable[-1])[2].empty?
            if Kana_single.include? char
              transcript += syllable
              syllable = Kana_single[char]
            else
              transcript += syllable + char
            end
          else
            if Kana_single.include? char
              transcript += syllable
              syllable = Kana_single[char]
            elsif char == "っ"
              last_char = break_hangul(syllable[-1])
              syllable = syllable[0..-2] + assemble_hangul(last_char[0], last_char[1], 'ㅅ')
            elsif Yo_on.include? char
              if Kana_before_yo_on.include? syllable[-1]
                last_char = break_hangul(syllable[-1])
                syllable = syllable[0..-2] + assemble_hangul(last_char[0], Yo_on[char], '')
              else
                transcript += syllable + char
                syllable = ""
              end
            elsif char == "ん"
              syllable += "ん"
            else
              transcript += syllable + char
              syllable = ""
            end
          end
          if Punctuation.values.include? transcript[-1] and transcript[-2] == '챵'
            transcript = transcript[0..-3] + '쨩' + transcript[-1]
          end
        end
        if not syllable.empty?
          if syllable[-1] == 'ん'
            last_char = break_hangul(syllable[-2])
            transcript += syllable[0..-3] + assemble_hangul(last_char[0], last_char[1], 'ㅇ')
          else
            transcript += syllable
          end
          if transcript[-1] == '챵'
            transcript = transcript[0..-2] + '쨩'
          end
        end
        transcript += "\n" + translate_ntranstalk(:j2k, line, '1', '1').sub(' "', '"') + "\n"
      end
    else
      transcript += "\n"
    end
    transcript += "\n"
  end

  result = %{<html>
<head>
<title>일본어 노래 가사 자동 번역기</title>
</head>
<body>
  <div>}
  transcript.chomp.lines.each do |line|
    result += line + '<br />'
  end
  result += %{</div>
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
    'User-Agent' => 'Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/28.0.1500.95 Safari/537.36',
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

Cho_list = [
  'ㄱ', 'ㄲ', 'ㄴ', 'ㄷ', 'ㄸ', 'ㄹ', 'ㅁ', 'ㅂ', 'ㅃ',
  'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅉ', 'ㅊ', 'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
]
Jung_list = [
  'ㅏ', 'ㅐ', 'ㅑ', 'ㅒ', 'ㅓ', 'ㅔ',
  'ㅕ', 'ㅖ', 'ㅗ', 'ㅘ', 'ㅙ', 'ㅚ',
  'ㅛ', 'ㅜ', 'ㅝ', 'ㅞ', 'ㅟ', 'ㅠ',
  'ㅡ', 'ㅢ', 'ㅣ'
]
Jong_list = [
  '', 'ㄱ', 'ㄲ', 'ㄳ', 'ㄴ', 'ㄵ', 'ㄶ', 'ㄷ',
  'ㄹ', 'ㄺ', 'ㄻ', 'ㄼ', 'ㄽ', 'ㄾ', 'ㄿ', 'ㅀ',
  'ㅁ', 'ㅂ', 'ㅄ', 'ㅅ', 'ㅆ', 'ㅇ', 'ㅈ', 'ㅊ',
  'ㅋ', 'ㅌ', 'ㅍ', 'ㅎ'
]

def break_hangul(char)
  code = char.ord - 44032
  cho = code / 588
  jung = code % 588 / 28
  jong = code % 588 % 28
  return [Cho_list[cho], Jung_list[jung], Jong_list[jong]]
end

def assemble_hangul(cho, jung, jong)
  return (44032 + Cho_list.index(cho) * 588 + Jung_list.index(jung) * 28 + Jong_list.index(jong)).chr('UTF-8')
end
