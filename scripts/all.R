# パッケージ, 共通設定等の読み込み
source("scripts/set_environments.R")


# スクレイピング
source(here(dirname_scripts, "scraping.R"))
sources <- map2_dfr(
  list(source1, source2, source3, source4, source5, source6, source7, source8, source9, source10, source11, source12, source13),
  1:13,
  function(x, t) tibble(x) %>% mutate(title=t, page=row_number())
) %>% mutate(html=map(x, as.character)) %>% select(-x)
write_rds(sources,  here(dirname_data, "sources.rds"))


# 取得データの整然化
sources <- read_rds(here(dirname_data, "sources.rds"))
source(here(dirname_scripts, "tidying.R"))
save(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13, file=here("data", "df.RData"))
rm(sources, df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13)


# 名寄せ処理
load(here(dirname_data, "df.RData"))

# 予め手作業で作った名寄せテーブルを読み込み
# TODO: 名寄せ処理のさらなる向上
persona_non_grata <- read_csv(here(dirname_data, "persona_non_grata.csv"))
df_identity <- distinct(
  bind_rows(read_csv(here(dirname_data, "df_non_jis.csv")), # 機種依存文字
            read_csv(here(dirname_data, "df_name_length.csv")), # 長い名前調査の結果
            read_csv(here(dirname_data, "df_name_length.csv")), # 勘と経験
            read_csv(here(dirname_data, "df_alias2.csv")) # 機械学習
  )) %>% distinct
df_name_wiki <- read_csv(here(dirname_data, "df_name_wiki.csv"))
df_name_mujins <- read_csv(here(dirname_data, "df_name_mujins.csv"))
source(here(dirname_scripts, "merge.R") )
write_rds(df_all, path = here("data", "df_all.rds"))


# 
df_all <- read_rds(path = here(dirname_data, "df_all.rds"))
df_all <- df_all %>% rename(name_old = name)

load(here(dirname_scripts, "analysis.R"))
