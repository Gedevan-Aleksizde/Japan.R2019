# 全体の流れはall.Rで管理しています
# run source("scripts/set_environments.R") first if you want to run this single script

# 1-7, 12
# http://hima.que.ne.jp/sangokushi/
get_robotstxt("http://hima.que.ne.jp/sangokushi/12/san12_data.cgi?up1=0")
# 8
# http://web.archive.org/web/20120604085907/http://yo7.org/3594/san8/db/trtk.html
# 9
get_robotstxt("http://lee.serio.jp/novel/sangoku/san9busho.html")
# 10
get_robotstxt("http://channel2.s151.xrea.com/sansen/san10/10-ichiran.html")
# 11
get_robotstxt("https://w.atwiki.jp/sangokushi11/pages/148.html")
# 13
get_robotstxt("https://sangokushi13wiki.wiki.fc2.com/wiki/%E6%AD%A6%E5%B0%86%E4%B8%80%E8%A6%A7")

#### ダウンロードする ####

# I
# https://localmajorroad.blogspot.com/2017/11/blog-post_18.html こっちのほうがミスが少なかったのでこっちから取ればよかった
url_1 <- "http://hima.que.ne.jp/sangokushi/sangokushi01.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source1 <- list()
for(i in 1:3){
  source1[[i]] <- read_html(paste0(url_1, i-1))
  Sys.sleep(10)
}
# II
url_2 <- "http://hima.que.ne.jp/sangokushi/sangokushi02.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=200;p="
source2 <- list()
for(i in 1:4){
  source2[[i]] <- read_html(paste0(url_2, i-1))
  Sys.sleep(10)
}
# III
url_3 <- "http://hima.que.ne.jp/sangokushi/sangokushi03.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source3 <- list()
for(i in 1:6){
  source3[[i]] <- read_html(paste0(url_3, i-1))
  Sys.sleep(10)
}
# IV
url_4 <- "http://hima.que.ne.jp/sangokushi/sangokushi04.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source4 <- list()
for(i in 1:6){
  source4[[i]] <- read_html(paste0(url_4, i-1))
  Sys.sleep(10)
}
# V
url_5 <- "http://hima.que.ne.jp/sangokushi/sangokushi05.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source5 <- list()
for(i in 1:5){
  source5[[i]] <- read_html(paste0(url_5, i-1))
  Sys.sleep(10)
}
# VI
url_6 <- "http://hima.que.ne.jp/sangokushi/sangokushi06.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source6 <- list()
for(i in 1:6){
  source6[[i]] <- read_html(paste0(url_6, i-1))
  Sys.sleep(10)
}
# VII
url_7 <- "http://hima.que.ne.jp/sangokushi/sangokushi07.cgi?up1=0&keys2%2C6=&index=&IDn001=AND&sort=up6s&print=100;p="
source7<- list()
for(i in 1:6){
  source7[[i]] <- read_html(paste0(url_7, i-1))
  Sys.sleep(10)
}
# VIII
source8 <- list(
  read_html("http://web.archive.org/web/20120604085907/http://yo7.org/3594/san8/db/trtk.html", encoding="cp932"),
  read_html("http://web.archive.org/web/20120604090337/http://yo7.org/3594/san8/db/mask.html", encoding="cp932")
  )

# IX
source9 <- list(read_html("http://lee.serio.jp/novel/sangoku/san9busho.html"))
# X
source10 <- list(read_html("http://channel2.s151.xrea.com/sansen/san10/10-ichiran.files/sheet007.html"))
# 11
source11 <- list(read_html("https://w.atwiki.jp/sangokushi11/pages/148.html"))
# 12
url_12 <- "http://hima.que.ne.jp/sangokushi/12/san12_data.cgi?up1=0;print=100;p="
source12 <- list()
for(i in 1:6){
  source12[[i]] <- read_html(paste0(url_12, i-1))
  Sys.sleep(10)
}
# 13
source13 <- list(read_html("https://sangokushi13wiki.wiki.fc2.com/wiki/%E6%AD%A6%E5%B0%86%E4%B8%80%E8%A6%A7"))


# tidying.R へ続く
