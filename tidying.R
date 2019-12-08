pacman::p_load(tidyverse, ggthemes, rvest, skimr, stringr, stringi, here, datapasta)

# 名前の重複を見つける関数
check_dup <- function(x){
  x %>% group_by(name) %>% summarise(n=n()) %>% filter(n>1) %>% inner_join(x, by="name") %>%
    dplyr::select(title, order, name, n, everything())
}

sources <- read_rds(here("data", "sources.rds"))

##### I #####
df1_header <- filter(sources, title == 1)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header = F) %>% as.character
df1_header[1] <- "name"
df1 <- tibble()
for(i in 1:3){
  df1 <- bind_rows(
    df1,
    filter(sources, title == 1)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow=T, nrow=1), stringsAsFactors=F))
  )
}
df1 <- df1 %>% set_names(df1_header) %>%
  filter(name != "武将名") %>% mutate_at(.vars = vars(身体, 知力, 武力, カリスマ, 運勢), as.integer) %>%
  mutate(title = "1", order = row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df1)

df1$name[
  c(61, 77, 113, 125, 137, 139:140, 143, 145, 154:155, 172, 208, 221, 223, 227, 239, 245, 250)
  ] <- c("侯選", "宋謙", "蔡邕", "孫乾", "張儀", "張郃", "張紘", "張松", "趙岑", "陳紀", "陳嬉",
         "陶謙", "楊修", "李湛", "李豊 (東漢)", "劉璝", "劉曄","梁剛", "呂廣")
check_dup(df1)

###### II #####
df2_header <- filter(sources, title == 2)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header = F) %>% as.character
df2_header[1] <- "name"
df2 <- tibble()
for(i in 1:4){
  df2 <- bind_rows(
    df2,
    filter(sources, title == 2)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow = T, nrow = 1), stringsAsFactors = F))
  )
}
df2 <- df2 %>% set_names(df2_header) %>% filter(name != "武将名") %>%
  mutate_at(.vars = vars(知力, 武力, 魅力, 義理, 野望, 相性), .funs = as.integer)
df2 <- mutate(df2, title = "2", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df2)
# 名前が重複しているものは読みの欄から入力ミスとみなして修正
# 読みが同じ場合は相性やステータスの特徴から判定
# 鄧賢/陶謙, 劉繇/劉曄はゲーム実際にやってないと識別難しいのでは?
df2$name[c(62, 125, 296, 24, 218, 220, 234, 279)] <- c("楽就", "辛評", "劉曄", "賈華", "陶謙", "董衡", "馬忠 (孫呉)", "李豊 (東漢)")
check_dup(df2)

##### III ####
df3_header <- filter(sources, title == 3)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header=F) %>% as.character
df3_header[1] <- "name"
df3 <- tibble()
for(i in 1:6){
  df3 <- bind_rows(
    df3,
    filter(sources, title == 3)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow = T, nrow = 1), stringsAsFactors = F))
  )
}
df3 <- set_names(df3, df3_header) %>% filter(name != "武将名") %>%
  mutate_at(.vars = vars(知力, 武力, 政治, 魅力, 陸指, 水指, 義理, 相性), .funs = as.integer)
df3 <- mutate(df3, title = "3", order = row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df3)
# 374, 375 が鄧艾でダブってる. 読みの欄から375は鄧義の誤りとみなす
# TODO: 312, 313 は...
df3$name[c(375, 403, 479)] <- c("鄧義", "馬忠 (孫呉)", "李豊 (東漢)")
# 3 だけ張闓が二人登場する. 片方は袁術配下? しかし後漢書の全訳が出たのは 2001 年, 1970年のものは陳敬王伝は訳されてない
# https://sites.google.com/site/sanhumanity/ze/zhang-kai
df3$name[313] <- c("張闓 (袁術)")
check_dup(df3)


##### IV ######
df4_header <- filter(sources, title == 4)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header = F) %>% as.character
df4_header[1] <- "name"
df4 <- tibble()
for(i in 1:5){
  df4 <- bind_rows(
    df4,
    filter(sources, title == 4)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow = T, nrow = 1), stringsAsFactors = F))
  )
}
df4 <- df4 %>% set_names(df4_header) %>% filter(name != "武将名") %>%
  mutate(誕生年 = str_replace(誕生年, "\\r年", "")) %>%
  mutate_at(.vars = df4_header[-(1:2)], .funs = as.integer)
df4 <- mutate(df4, title = "4", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df4)
# 蜀の馬忠初登場. 354 が蜀のほう. 紛らわしいので名前に所属を入れる
df4$name[c(288, 353:354, 419)] <- c("張南 (東漢)", "馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)")
check_dup(df4)


##### V #####
df5_header <- filter(sources, title == 5)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header = F) %>% as.character
df5_header[1] <- "name"
df5 <- tibble()
for(i in 1:5){
  df5 <- bind_rows(
    df5,
    filter(sources, title == 5)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow = T, nrow = 1), stringsAsFactors = F))
  )
}
df5 <- df5 %>% set_names(df5_header) %>% filter(name != "武将名") %>% mutate(誕生年 = str_replace(誕生年, "\\r年", "")) %>%
  mutate_at(.vars = df5_header[-(1:2)], .funs = as.integer) %>%
  mutate(title = "5", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df5)
# 199 は生年, 相性などから 譙周
df5$name[c(199, 231, 396, 397, 377, 373, 401, 403, 464)] <- c(
  "譙周", "全禕", "馬忠 (孫呉)", "馬忠 (蜀漢)", "鄧茂", "鄧忠", "馬邈", "万彧", "李豊 (蜀漢)")
check_dup(df5)

##### VI #####
df6_header <- filter(sources, title == 6)$html[[1]] %>% read_html %>% html_node("table") %>% html_table(header = F) %>% as.character
df6_header[1] <- "name"
df6 <- tibble()
for(i in 1:6){
  df6 <- bind_rows(
    df6,
    filter(sources, title == 6)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
      map_dfr(function(x) data.frame(matrix(as.character(x), byrow = T, nrow = 1), stringsAsFactors = F))
  )
}
df6 <- df6 %>% set_names(df6_header) %>% filter(name != "武将名") %>%
  mutate(字=na_if(字, "-")) %>% mutate_at(.vars = df6_header[-(1:4)], .funs = as.integer) %>%
  mutate(夢 = as.factor(夢)) %>%
  mutate(title = "6", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df6)
df6$name[c(347, 409:410, 481)] <- c("張南 (蜀漢)", "馬忠 (蜀漢)", "馬忠 (孫呉)", "李豊 (蜀漢)")


###### VII ######
df7_header <- filter(sources, title==7)$html[[1]] %>% read_html %>% html_node("table") %>%
  html_table(header=F, fill=T) %>% unlist %>% as.character
df7_header[2] <- "name"
df7_header[c(1, 3, 13, 14)] <- c("読み", "字読み", "c1", "c2")
df7 <- tibble()
for(i in 1:6){
  df7 <- bind_rows(
    df7,
    filter(sources, title==7)$html[[i]] %>% read_html %>% html_nodes("table") %>% html_table(fill=T) %>%
      map_dfr(function(x) unlist(as.character(unlist(x))) %>% matrix(byrow=T, nrow=1) %>% data.frame(stringsAsFactors=F))
  )
}

df7 <- df7 %>% set_names(df7_header) %>% filter(name!="武将名") %>%
  mutate(字 = na_if(字, "-")) %>% dplyr::select(-c1, -c2, -`字読み`) %>% mutate_at(.vars = df7_header[-c(1:4, 13:15)], .funs = as.integer) %>%
  mutate(title = "7", order = row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df7)
df7$name[c(424:425, 497)] <- c("馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)")

##### VIII ####
df8 <-  html_node(filter(sources, title == 8)$html[[1]] %>% read_html, "table") %>% html_table(header = T) %>% as_tibble %>%
  mutate_all(.funs = function(x) na_if(x, "")) %>%
  mutate(
    戦術 = str_split(pattern = "・", 戦術),
    特技 = str_split(pattern = "・", 特技)
  ) %>% unnest(cols = 戦術) %>%
  mutate(
    戦術LV = str_replace(戦術, "^.+\\((.+)\\)$", "\\1") %>%
      factor(levels = c(NA, "初", "弐", "参", "四", "伍", "極"), labels = c(0, 1, 2, 3, 4, 5), ordered = T) %>% as.integer,
    戦術 = str_replace(戦術, "^(.+)\\(.+$", "\\1")
  ) %>% pivot_wider(names_from = 戦術, values_from = 戦術LV, values_fill = list(戦術LV = 0)) %>% 
  dplyr::select(-`NA`) %>%
  unnest(cols=特技) %>% mutate(flg = T) %>% pivot_wider(names_from = 特技, values_from = flg, values_fill = list(flg = 0)) %>%
  dplyr::select(-`NA`) %>%
  rename(name = 名前) %>% rename_if(is.logical, ~paste0(.x, "lgl"))
df8 <- df8 %>% mutate(title = "8", order = row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df8)
df8$name[c(317, 337, 560, 403, 404, 479)] <- c("張温 (東漢)", "張南 (東漢)", "張温 (孫呉)", "馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)")

df8_mask <- filter(sources, title==8)$html[[2]] %>% read_html %>% html_node("table") %>%
  html_table(header=T) %>% as_tibble %>% rename(name = 名前) %>% mutate(order=row_number())
df8_mask %>% group_by(name) %>% summarise(n=n()) %>% filter(n > 1) %>% inner_join(df8_mask, by = "name")
df8_mask$name[c(317, 337, 560, 403, 404, 479)] <- c("張温 (孫呉)", "張南 (東漢)", "張温 (東漢)", "馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)")
df8 <- left_join(df8, dplyr::select(df8_mask, -order), by="name") %>%
  mutate_at(vars(人物傾向, 戦略傾向, 成長タイプ), as.factor)
# PK 情報は使わない
check_dup(df8)

##### IX #####
# フラグ変換処理が大量にある
df9 <- filter(sources, title == 9)$html[[1]] %>% read_html %>% html_node("table") %>% html_node("table") %>% html_table(header = T) %>% as_tibble
df9 <- filter(df9, ID != "ID") %>%
  mutate_all(na_if, "") %>% fill(ID) %>%
  mutate_at(.vars = vars(統率, 武力, 知力, 政治, 誕生, 寿命, 相性, 義理, 野望), .funs = as.integer) %>%
  rename(name = 名前)
df9 <- df9 %>%
  dplyr::select(-奮奮奮戦闘迅, -突突突破進撃, -騎走飛射射射, -斉連連射射弩, -蒙楼闘衝船艦, -井衝投象闌車石兵,
                -造石罠教営兵破唆, -`混罠心幻乱＿攻術`, -罵鼓治妖声舞療術) %>%
  bind_cols(str_split_fixed(df9$奮奮奮戦闘迅, pattern = "", 3) %>% data.frame) %>% rename(奮戦 = X1, 奮闘 = X2, 奮迅 = X3) %>%
  bind_cols(str_split_fixed(df9$突突突破進撃, pattern = "", 3) %>% data.frame) %>% rename(突破 = X1, 突進 = X2, 突撃 = X3) %>%
  bind_cols(str_split_fixed(df9$騎走飛射射射, pattern = "", 3) %>% data.frame) %>% rename(騎射 = X1, 走射 = X2, 飛射 = X3) %>%
  bind_cols(str_split_fixed(df9$斉連連射射弩, pattern = "", 3) %>% data.frame) %>% rename(斉射 = X1, 連射 = X2, 連弩 = X3) %>%
  bind_cols(str_split_fixed(df9$蒙楼闘衝船艦, pattern = "", 3) %>% data.frame) %>% rename(蒙衝 = X1, 楼船 = X2, 闘艦 = X3) %>%
  bind_cols(str_split_fixed(df9$井衝投象闌車石兵, pattern = "", 4) %>% data.frame) %>% rename(井闌 = X1, 衝車 = X2, 投石 = X3, 象兵 = X4) %>%
  bind_cols(str_split_fixed(df9$造石罠教営兵破唆, pattern = "", 4) %>% data.frame) %>% rename(造営 = X1, 石兵 = X2, 罠破 = X3, 教唆 = X4) %>%
  bind_cols(str_split_fixed(df9$`混罠心幻乱＿攻術`, pattern = "", 4) %>% data.frame) %>% rename(混乱 = X1, 罠 = X2, 心攻 = X3, 幻術 = X4) %>%
  bind_cols(str_split_fixed(df9$罵鼓治妖声舞療術, pattern = "", 4) %>% data.frame) %>% rename(罵声 = X1, 鼓舞 = X2, 治療 = X3, 妖術 = X4)
df9 <- mutate_at(df9, .vars = colnames(df9)[15:45], function(x) if_else(x == "×", F, T)) %>%
  rename_if(is.logical, ~paste0(.x, "lgl")) %>%
  mutate(性格 = factor(性格)) %>%
  filter(name != "俺様") %>%
  mutate(title = "9", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df9) %>% filter(!str_detect(name, "武将"))
df9$name[c(414, 501:502, 600:601)] <- c("張南 (蜀漢)", "馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (東漢)", "李豊 (蜀漢)")
df9$name[346] <- c("孫匡") # この後の確認で名前に字が混入していたことを発見


###### X #####
df10 <- filter(sources, title == 10)$html[[1]] %>% read_html %>% html_nodes("table") %>% html_table() %>%
  .[[1]] %>% as_tibble
df10_header <- as.character(df10[2, ])
df10_header[2] <- "name"
df10 <- df10[-(1:2), ] %>% set_names(df10_header) %>% dplyr::select(-c(1, 8)) %>%
  filter(name != "") %>%
  mutate(name = stri_trans_nfkc(name)) # 今後を考えて半角カナを全角に
df10 <- mutate_at(df10, vars(統率, 武力, 知力, 政治, 魅力), as.numeric)
df10 <- mutate(df10, title = "10", order = row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df10)
df10$name[c(59, 403, 239, 382, 442)] <- c("馬忠 (蜀漢)", "馬忠 (孫呉)", "李豊 (蜀漢)", "李豊 (東漢)", "李豊 (曹魏)")

##### 11 #####
df11 <- filter(sources, title == 11)$html[[1]] %>% read_html %>% html_nodes("table:nth-child(-n+3)") %>% html_table %>%
  bind_rows() %>% filter(相性!="相性") %>% as_tibble %>%
  mutate(相性 = na_if(相性, "-") %>% as.integer) %>%
  mutate_at(.vars = vars(登場, 探索, 父親), .funs = function(x) na_if(x, "")) %>%
  mutate_at(.vars = vars(特技, 槍兵, 戟兵, 弩兵, 騎兵, 兵器, 水軍), .funs = as.factor) %>%
  mutate_at(.vars = vars(統率, 武力, 知力, 政治, 魅力, 生年, 没年, 登場), as.integer) %>%
  rename(name=名前) %>% rename_if(is.factor, ~paste0(.x, "fct")) %>%
  mutate(title="11", order=row_number()) %>% dplyr::select(title, order, name, everything())
check_dup(df11)
df11$name[c(430:431, 515:516, 613:615)] <- c("張南 (東漢)", "張南 (蜀漢)", "馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)", "李豊 (曹魏)", "李豊 (東漢)")

##### 12 #####
# タグ属性にも情報があるので処理が面倒なフォーマット
df12_header <- filter(sources, title == 12)$html[[1]] %>% read_html %>% html_nodes("table") %>% html_table %>%
  .[[1]] %>% as.matrix %>% as.character
df12_header[grepl("^特技$", df12_header)] <- paste0("特技", 1:length(grep("^特技$", df12_header)))
df12_header[1:4] <- c("名前読み", "名前", "字読み", "字")
df12_header[c(18, 20)] <- c("戦法2", "戦法3")
df12_header[38] <- "口調2"
df12_header[42] <- "格付け2"

parse_table12_by_page <- function(x, header){
  d_main <- x %>% html_nodes("table") %>% html_table %>% map(function(x) as.character(unlist(x)) %>% matrix(nrow = 1, byrow = T) %>%
                                                               as.data.frame(stringsAsFactors = F) %>% set_names(header)) %>%
    bind_rows %>% filter(名前読み!="武将名")
  d_flag <- x %>% html_nodes("table") %>% html_nodes(".on, .off") %>% html_attr("class") %>% {ifelse(. == "on", T, F)} %>% matrix(ncol = 20, byrow = T)
  d_main[sort(grep("^特技[0-9]+$", colnames(d_main)))] <- d_flag
  return(as_tibble(d_main))
}

df12 <- map_dfr(map(filter(sources, title == 12)$html, read_html),
                function(x) parse_table12_by_page(x, df12_header))
df12 %<>% dplyr::select(-`合計`, -`格付け`, -`格付け2`) %>%
  mutate_at(.vars = vars(統率, 武力, 知力, 政治, 義理, 勇猛, 相性, 誕生, 登場, 没年, 寿命), as.integer) %>%
  mutate_if(is.character, function(x) na_if(x, "-")) %>%
  mutate_at(.vars = vars(口調, 口調2), as.factor) %>%
  rename(name = 名前) %>% mutate(title = "12", order = row_number())  %>% dplyr::select(title, order, name, everything())
check_dup(df12)

# 呉の馬忠は落選
filter(df12, str_detect(name, "馬忠|李豊|張温")) %>% dplyr::select(name, 字, order, 相性, 誕生, 登場, 没年)
df12$name[c(257, 332, 403)] <- c("張温 (孫呉)", "馬忠 (蜀漢)", "李豊 (東漢)")

##### XIII #####
df13 <- filter(sources, title == 13)$html[[1]] %>% read_html %>% html_nodes("table") %>% html_table(header = T) %>% map(function(x) mutate_all(x, as.character)) %>%
  bind_rows %>% dplyr::select(-(1:12)) %>% filter(row_number() != 1) %>% as_tibble %>%
  mutate(相性 = na_if(相性, "?"), 重臣特性 = str_replace(重臣特性, "-", ""), 理想威名 = na_if(理想威名, "？")) %>%
  mutate_at(.vars = vars(相性, 生年, 登場, 没年, 統率, 武力, 知力, 政治), .funs = as.integer) %>%
  mutate_at(.vars = vars(槍兵, 騎兵, 弓兵, 伝授特技, 重臣特性, 戦法, 理想威名), .funs = as.factor) %>%
  rename(name = 名前, 槍兵fct = 槍兵, 騎兵fct = 騎兵, 弓兵fct = 弓兵) %>% mutate(title = "13", order = row_number()) %>% dplyr::select(title, order, name, everything())

check_dup(df13)
df13$name[c(415, 497, 780, 591, 770, 788:789)] <- c("張南 (東漢)", "馬忠 (蜀漢)", "馬忠 (孫呉)", "李豊 (東漢)", "張南 (蜀漢)", "李豊 (蜀漢)", "李豊 (曹魏)")

#####

save(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13, file="data/df.RData")
rm(sources, df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13)
# merge.R へ続く
