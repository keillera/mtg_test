require 'open-uri'
require 'nokogiri'

class MtgTop8

  TARGET_URL = 'http://www.mtgtop8.com/'
  TARGET_DIR = '/Users/keiju/tmp'
  def export_decks
    target_urls = { standard: TARGET_URL + 'format?f=ST',
#                    modern: TARGET_URL + 'format?f=MO',
#                    legacy: TARGET_URL + 'format?f=LE',
#                    vintage: TARGET_URL + 'format?f=VI'
    }


    meta_urls = {}
    target_urls.each { |k, v|
      meta_urls[k] = get_meta_urls v
    }

    event_urls = {}
    meta_urls.each { |k, v|
      event_urls[k] = v.map { |url|
        get_event_urls url
      }.flatten
    }
    # 出力先のディレクトリを作成
    date_str = Time.now.strftime("%Y%d%m_%H%M%S")
    Dir.mkdir("#{TARGET_DIR}/#{date_str}")

    event_urls.each { |k, v|
      count = 0
      v.each{ |url|
        File.open("#{TARGET_DIR}/#{date_str}/#{k}_#{count}", 'w') {|file|
          target_url = get_export_url url
          file.write get_mw_deck target_url
        }
        count += 1
      }
    }
  end

  def get_meta_urls url
    doc = get_doc url
    doc.xpath("/html/body/div[3]/div/table/tr/td[1]/table/tr[@class='hover_tr']").map do |item|
      TARGET_URL + item.children[1].children.attribute('href').to_s
    end
  end

  def get_event_urls url
    doc = get_doc url
    doc.xpath("/html/body/div[3]/div/table/tr/td[2]/form[1]/table/tr[@class='hover_tr']").map do |item|
      TARGET_URL + item.children[3].children.attribute('href').to_s
    end
  end

  def get_export_url url
    doc = get_doc url
    TARGET_URL + doc.xpath("html/body/div[3]/div/table/tr/td[2]/table/tr[1]/td/table/tr/td[3]/div/a").first.attribute('href').to_s
  end

  def get_doc url
    charset = nil
    html = open(url) do |f|
      charset = f.charset
      f.read
    end
    # htmlをパース
    Nokogiri::HTML.parse(html, nil, charset)
  end

  def get_mw_deck url
    mw = open(url) do |f|
      f.read
    end
    deck_str = ''
    sb_flg = false
    mw.lines.map do |line|
      # サイドボードの境界の文を追加
      if sb_flg == false && line.match("^SB:.*")
        sb_flg = true
        deck_str += '// Sideboard' + "\n"
      end

      # サイドボードの場合はSB:の文言を含めない
      if sb_flg
        line.slice!(0, 4)
      end
      deck_str += line
    end
    return deck_str
  end

end


hoge = MtgTop8.new
hoge.export_decks
#puts hoge.get_mw_deck "http://www.mtgtop8.com/export_files/deck266570.mwDeck"