pacman::p_load(tidyverse, ggthemes, lubridate)

df_tl <- tribble(
  ~"category", ~"start", ~"end", ~"title", ~"author", ~"publisher", ~"source",
  "小説",   "1939",    "1943",    "吉川『三国志』",     "吉川英治", "大日本雄辯會講談社", "https://ja.wikipedia.org/wiki/%E4%B8%89%E5%9B%BD%E5%BF%97_(%E5%90%89%E5%B7%9D%E8%8B%B1%E6%B2%BB)",
  "漫画",   "1971",    "1987",    "横山『三国志』",     "横山光輝", "", "https://ja.wikipedia.org/wiki/%E4%B8%89%E5%9B%BD%E5%BF%97_(%E6%A8%AA%E5%B1%B1%E5%85%89%E8%BC%9D%E3%81%AE%E6%BC%AB%E7%94%BB)",
  "小説",   "1974",    "1977",    "陳『秘本三国志』",   "陳舜臣", "文藝春秋", "https://ja.wikipedia.org/wiki/%E7%A7%98%E6%9C%AC%E4%B8%89%E5%9B%BD%E5%BF%97",
  "史書",   "1977",    "1977",    "魏書 (一部)",        "今鷹真・井波律子", "筑摩書房", "",
  "史書",   "1982",    "1982",    "魏書・呉書",         "今鷹・小南・井波", "筑摩書房", "",
  "史書",   "1989",    "1989",    "魏書・呉書",         "小南", "筑摩書房", "",
  "史書",   "1995",    "",        "華陽国志",            "", "", "",
  "史書",   "2001",    "",        "後漢書", "", "", "4000088610",
  "史書",   "1996",    "",        "資治通鑑", "", "", "",
  "映像",   "1982",    "1984",    "『人形劇三国志』",   "NHK", "", "https://www2.nhk.or.jp/archives/tv60bin/detail/index.cgi?das_id=D0009010269_00000",
  "小説",   "1958",    "1959",    "立間『三国志演義』", "立間祥介", "平凡社", "https://ja.wikipedia.org/wiki/%E4%B8%89%E5%9B%BD%E5%BF%97%E6%BC%94%E7%BE%A9#cite_note-9",
  "漫画",   "1984",    "1984",    "『天地を喰らう』",   "本宮ひろ志", "集英社", "https://ja.wikipedia.org/wiki/%E5%A4%A9%E5%9C%B0%E3%82%92%E5%96%B0%E3%82%89%E3%81%86",
  "小説",   "1991",    "1991",    "『反三国志 (超・三国志)』", "周大荒", "講談社 (光栄)", "https://ja.wikipedia.org/wiki/%E5%8F%8D%E4%B8%89%E5%9B%BD%E5%BF%97%E6%BC%94%E7%BE%A9",
  "漫画",   "1994", "2005", "『蒼天航路』",       "王欣太・李學仁", "講談社", "https://ja.wikipedia.org/wiki/%E8%92%BC%E5%A4%A9%E8%88%AA%E8%B7%AF",
  "小説",   "1996",    "1998",    "北方『三国志』",     "北方謙三", "角川春樹事務所", "https://ja.wikipedia.org/wiki/%E4%B8%89%E5%9B%BD%E5%BF%97_(%E5%8C%97%E6%96%B9%E8%AC%99%E4%B8%89)",
  "ゲーム", "2001", "2001", "『鄭問之三國誌』",   "ゲームアーツ", "", "https://dic.nicovideo.jp/a/%E9%84%AD%E5%95%8F%E4%B9%8B%E4%B8%89%E5%9C%8B%E8%AA%8C",
  "小説",   "2001",  "2013",  "宮城谷『三国志』",   "宮城谷昌光", "文藝春秋", "https://books.bunshun.jp/articles/-/2346https://books.bunshun.jp/articles/-/2346",
  "漫画",   "2000",    "2019",    "『一騎当千』",       "塩崎雄二", "ワニブックス・少年画報社", "https://ja.wikipedia.org/wiki/%E4%B8%80%E9%A8%8E%E5%BD%93%E5%8D%83_(%E6%BC%AB%E7%94%BB)",
  "映像",   "2009",    "2009",    "『蒼天航路』", "", "", "",
  "映像",   "1985",    "1985",    "『三国志』(日本テレビ)", "", "", "",
  "映像",   "1991", "1992",  "『横山光輝 三国志』", "", "", "https://ja.wikipedia.org/wiki/%E6%A8%AA%E5%B1%B1%E5%85%89%E8%BC%9D_%E4%B8%89%E5%9B%BD%E5%BF%97",
  "映像",   "2007",  "2007",  "『鋼鉄三国志』", "", "", "http://www.nasinc.co.jp/jp/koutetsu-sangokushi/",
  "映像",   "2010",  "2011",  "『最強武将伝 三国演義』", "", "", "https://www.tv-osaka.co.jp/ip4/sangokuengi/index.html",
  "映像",   "2008",    "2009",    "『レッドクリフ』", "", "", "",
  "映像",   "2010",    "2010",    "Three Kingdoms", "", "", "",
  "ゲーム", "1992",    "1992",    "『横山光輝 三国志』", "", "", "https://ja.wikipedia.org/wiki/%E6%A8%AA%E5%B1%B1%E5%85%89%E8%BC%9D_%E4%B8%89%E5%9B%BD%E5%BF%97_(%E3%82%B2%E3%83%BC%E3%83%A0)",
  "ゲーム", "1988",    "1988",    "三国志 中原の覇者", "旧ナムコ", "", "https://ja.wikipedia.org/wiki/%E4%B8%89%E5%9B%BD%E5%BF%97_%E4%B8%AD%E5%8E%9F%E3%81%AE%E8%A6%87%E8%80%85",
  "ゲーム", "1985",    "",        "三國志I", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1989",    "",        "三國志II", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1992",    "",        "三國志III", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1994",    "",        "三國志IV", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1995",    "",        "三國志V", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "1995",    "",        "三國志英傑伝", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "1996",    "",        "三國志孔明伝", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1997",    "",        "三國無双", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "1998",    "",        "三國志VI", "光栄", "",  "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "1998",    "",        "三國志曹操伝", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2000",    "",        "三國志VII", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2000",    "",        "真・三國無双", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2001",    "",        "三國志VIII", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "2000",    "",        "真・三國無双2", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2002",    "",        "三國志戦記", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2003",    "",        "三國志IX", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "2003",    "",        "真・三國無双3", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2004",    "",        "三國志X", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "2005",    "",        "真・三國無双4", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2006",    "",        "三國志11", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "2007",    "",        "真・三國無双5", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  #"ゲーム", "2011",    "",        "真・三國無双6", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2012",    "",        "三國志12", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
  "ゲーム", "2016",    "",        "三國志13", "光栄", "", "https://www.gamecity.ne.jp/sangokushi30th/history.html",
)
df_tl <- df_tl %>% mutate(
  end = if_else(end == "", start, end) %>% as.integer,
  start = as.integer(start),
  category = factor(category, levels = c("ゲーム", "漫画", "映像", "小説", "史書"))
  ) %>%
  mutate(flag = (author == "光栄") & str_detect(title, "^三國志[A-Z0-9]"))
theme_document <- theme_classic(base_family = "Noto Sans CJK JP") +
  theme(legend.title = element_blank(), legend.position = "bottom",
        axis.title.y = element_text(angle = 0, vjust = .5))
theme_presen <- theme_classic(base_family = "Noto Sans CJK JP", base_size = 20) + theme(
  axis.title.y = element_blank(), axis.title.x = element_blank(),
  legend.title = element_blank(), legend.position = "bottom",
  legend.key.width = unit(3, "line"),
  title = element_blank()
)
g <- ggplot(df_tl %>% mutate(id = row_number()),
       aes(x = category,
           y = start, ymin = start, ymax = end,
           color = category, group = id
           )
       ) +
  geom_linerange(position = position_dodge2(width = .1)) +
  geom_point(size = 2, position = position_dodge(width = .1)) +
  geom_text(aes(label = title), hjust = "left", position = position_dodge(.1)) +
  scale_y_reverse() + labs(y = "西\n暦", x = "カテゴリ", title = "現代日本の三国志文化年表") + scale_color_wsj()
g + theme_document
ggsave(filename = "doc/timeline_doc.pdf", device = cairo_pdf)
g + theme_presen
ggsave(filename = "doc/timeline_presen.pdf", device = cairo_pdf, width = 10, height = 7)
