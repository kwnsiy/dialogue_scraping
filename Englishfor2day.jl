# coding:utf-8

doc =
"""
  対話データ収集プログラム
    http://www.englishfor2day.com/article/dialogue/?pg=1
"""

using Requests
using HttpCommon
using DataFrames 
using PyCall 
@pyimport bs4

# 対話データパース
# return dataframe
function get_dialogue(url)
  persons, utterances = [],[]
  request = get(url)
  html = readall(request)
  soup = bs4.BeautifulSoup(html)
  dialogue = convert(AbstractString, soup["find"]("div", class="dtlContent")["text"])
  for line in split(dialogue, r"\n|\r")[2:end]
    line = rstrip(line)
    (length(line) == 0 || ismatch(r"\d:\d",line) || !contains(line, ":")) && continue
    person, utterance = split(line, ":")
    push!(persons, person), push!(utterances, utterance)
  end
  @time sleep(0.3)
  return DataFrame(persons = persons, utterances = utterances)
end

# 対話データ記載ページ収集
# page_s = 1, page_e = 23
function dialogue_scraping(page_s, page_e)
  page, num = page_s, 0
  regex = r"""<a href="http://www.englishfor2day.com/article/dialogue/\d+".style"""
  while page <= page_e
    @printf "%s\n" "http://www.englishfor2day.com/article/dialogue/?pg=$page"
    request = get("http://www.englishfor2day.com/article/dialogue/?pg=$page")
    html, _ = split(readall(request), "<!--==========ad=========-->")
    dialogue_pages = [replace(m, r"^.+?\"|\".+?$", "") for m in matchall(regex, html)]
    for url in dialogue_pages
      @printf "%d : %s" num url
      df, num = get_dialogue(url), num + 1
      writetable("./dialogue_corpus/$num.dat", df, separator = '\t', header = true)
    end
    page += 1
  end
end

try
  mkdir("dialogue_corpus")
end
dialogue_scraping(1, 23)
