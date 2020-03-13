# 全体の流れはall.Rで管理しています

# load(file=here("data", "df.RData"))
df_all <- list(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13) %>%
  map_dfr(function(x) group_by(x, title, order, name) %>% nest %>% ungroup)

# ゲーム独自の創作人物, イベント専用っぽい人物は除外
# 例: 8 以降は春秋戦国・魏晉南北朝など別の時代の人物, 水滸伝の登場人物, 日本の戦国武将とかもいる
# TODO: 女性キャラの評価は適切なのか, 隠し要素になってないか
# 董白, 樊氏, 卞氏,  張春華,  呂玲綺, 糜氏,  蔡氏,  鮑三娘, 王元姫, 何氏,  夏侯氏, 郭氏, 甘氏, 甘氏

name_parenthesis <- c("馬忠 (孫呉)", "馬忠 (蜀漢)", "李豊 (蜀漢)", "李豊 (東漢)", "李豊 (曹魏)", "張温 (東漢)", "張温 (孫呉)", "張南 (東漢)", "張南 (蜀漢)", "張闓 (袁術)")
persona_non_grata <- read_csv("data/persona_non_grata.csv")
df_all <- filter(df_all, !name %in% persona_non_grata$name)


##### 名寄せ処理 #####
# 漢字以外の文字が使われている名前リストを取り出す
irregular_names <- filter(df_all, str_detect(name, "[^\\p{Han}]"), !name %in% name_parenthesis)
irregular_names$name %>% unique
# 名寄せのために新たに name_id を用意

df_identity <- irregular_names %>% group_by(name) %>% summarise(n=n()) %>% arrange(desc(n))
df_identity <- df_identity %>% filter(!name %in% name_parenthesis)
df_identity$name

# 予め手作業で作った名寄せテーブルを読み込み
# TODO: 名寄せ処理のさらなる向上
df_identity <- distinct(
  bind_rows(read_csv("data/df_non_jis.csv"), # 機種依存文字
            read_csv("data/df_name_length.csv"), # 長い名前調査の結果
            read_csv("data/df_alias.csv"), # 勘と経験
            read_csv("data/df_alias2.csv") # 機械学習
            )) %>% distinct

df_all <- left_join(df_all, select(df_identity, name, name_id), by="name") %>%
  mutate(name_id=coalesce(name_id, name))

filter(df_all, grepl("[^\\p{Han}]", name_id, perl=T), !name_id %in% name_parenthesis)$name_id %>% unique # 代字判定再確認

# 3字以上の名前は珍しいので確認
filter(df_all, str_length(name_id)>=3 & !name_id %in% name_parenthesis)$name_id %>% unique %>% sort

# 登場頻度の少ない人物も確認
tmp <- select(df_all, title, order, name,  name_id) %>% group_by(name_id) %>% summarise(n=n()) %>%
  arrange(n) %>% filter(n <= 2)
view(tmp)


# 名寄せ後に各タイトル内で重複がないか
df_all %>% group_by(title, name_id) %>% summarise(n=n()) %>% ungroup %>% filter(n>1)

# wiki, Mujins から取ってきた名前リストと照会
tmp <- select(df_all, name_id) %>% distinct %>% left_join(
  read_csv("data/df_name_wiki.csv") %>% select(name_id) %>% mutate(in_wiki = T),
  by = "name_id") %>% 
  left_join(read_csv("data/df_name_mujins.csv") %>% select(name_id) %>%mutate(in_mujins = T),
            by = "name_id")
tmp %>% filter(is.na(in_mujins) & is.na(in_wiki)) %>% view

# write_rds(df_all, path = here("data", "df_all.rds"))
# analysis.R へ続く
