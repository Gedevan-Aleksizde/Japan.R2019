# 全体の流れはall.Rで管理しています
# 注: Mac は以下のプログラムで正しくpdfの保存ができない

scale_max_min <- function(x){
  (x - min(x)) / (max(x) - min(x))
}

# skimr 設定
my_skim <- skim_with(numeric = sfl(n = length, mean = mean, skew = skewness, kurto = kurtosis, hist = NULL))

df_all <- read_rds(path = "data/df_all.rds")
df_all <- df_all %>% rename(name_old = name)

# シリーズの参加回数
attend_times <- df_all %>% group_by(name_id) %>% summarise(attend_times = n()) %>% ungroup 
# 初登場
at_first <- df_all %>% arrange(name_id, as.integer(title)) %>% group_by(name_id) %>% summarise(at_first = as.integer(first(title))) %>% ungroup
df_all <- inner_join(df_all, attend_times, by = "name_id") %>%
  inner_join(at_first, by = "name_id")



# ---- データの傾向をグラフで確認 ----

select(df_all, name_id, attend_times) %>% distinct %>%
  ggplot(aes(x = attend_times)) + geom_bar()

# 登場人物の採用・不採用の傾向
df_in_out <- df_all %>% select(title, name_id) %>% mutate(exists = T, title = as.integer(title)) %>%
  right_join(x = ., y = expand_grid(title = unique(.$title), name_id = unique(.$name_id)), by = c("title", "name_id")) %>%
  mutate(exists = if_else(is.na(exists), F, T)) %>%
  arrange(name_id, title) %>% group_by(name_id) %>% mutate(join = !lag(exists) & exists, out = !exists & lag(exists)) %>% ungroup

# 検算
df_in_out  %>% group_by(title) %>% summarise(size = sum(exists), join = sum(join), out = sum(out)) %>% ungroup %>%
  mutate(net = join - out, valid = (size - (lag(size) + net)) == 0)

df_in_out_summary <- df_in_out %>% group_by(title) %>% summarise_if(is.logical, sum) %>% ungroup %>%
  mutate(keep = exists - join) %>% select(-exists) %>%
  pivot_longer(-title, names_to = "var", values_to = "number") %>%
  mutate(var = factor(var, levels = c("out", "join", "keep"), labels = c("out", "in", "keep"))) %>%
  arrange(title, var)

g_in_out <- ggplot(df_in_out_summary, aes(x = title, y = number, group = var, fill = var,
             color = var, alpha = var != "out", linetype = (var == "out")
             )
         ) +
  geom_bar(stat = "identity", position = "stack", size = 1, width = .6) +
  scale_x_continuous(breaks = 2:13) + scale_fill_colorblind() +
  scale_alpha_manual(guide = F, breaks = c(F, T), values=c(0.1, 1)) +
  scale_linetype_manual(guide =F, values = c("solid", "dashed")) +
  scale_color_colorblind(guide = F) +
  labs(x = "タイトル", y = "人数")

g_in_out + theme_presen + labs(title = "In/Out")
ggsave(filename = "img/in_out_presen.pdf", device = cairo_pdf, width = 10, height = 6)
g_in_out + theme_document_no_y
ggsave(filename = "img/in_out_document.pdf", device = cairo_pdf)


# 人物ごと出入り回数の分布
df_in_out %>% mutate(keep = !join & !out) %>% select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  arrange(desc(out))

df_in_out %>% mutate(keep = !join & !out) %>% select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  arrange(desc(join))


df_in_out %>% mutate(keep = !join & !out) %>% select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  pivot_longer(-name_id, names_to = "var", values_to = "number") %>%
  ggplot(aes(x = number, y = after_stat(density), group = var, fill = var)) +
  geom_histogram(position = "identity", bins = 10) +
  facet_wrap(~var, ncol = 1) + scale_fill_pander()


map(1:13, function(x) filter(df_all %>% mutate(title = as.integer(title)), title == x) %>%
      unnest(cols = data) %>% select_if(is.numeric)) %>% bind_rows %>%
  select(title, 知力, 武力, 政治, 魅力, 統率) %>% group_by(title) %>% my_skim()

df_append <- df_all %>% group_by(title) %>% group_map(
  ~unnest(.x, cols = data) %>%
    rename_if(names(.) == "カリスマ", function(x) "魅力") %>%
    select_if(names(.) %in% c("title", "name_id") | map_lgl(., is.numeric)),
  keep = T
) %>% bind_rows %>%
  select(title, name_id, attend_times, at_first, 身体, 知力, 武力, 魅力, 運勢, 義理, 野望, 相性, 政治, 統率, 陸指, 水指) %>%
  mutate(title = factor(title, levels=1:13))

# シリーズ別ステータス値の要約統計量
descriptive_status <- df_append %>% group_by(title) %>% select(title, 武力, 知力, 魅力, 政治) %>% my_skim() %>%
  as_tibble() %>% rename_all(~str_remove(.x, "^numeric.")) %>% rename(missings = n_missing) %>% filter(skim_type == "numeric") %>%
  select(-skim_type, -complete_rate) %>% rename(variable = skim_variable, min = p0, max = p100, skewness = skew, kurtosis = kurto) %>%
  mutate(title = as.integer(title))
descriptive_status
Hmisc::latex(descriptive_status %>% mutate_if(is.numeric, ~formatC(.x, digits = 2, format = "f")) %>%
               select(title, variable, min, p25, p50, p75, max, mean, sd, skewness, kurtosis),
             file="img/tab_descriptive.tex", rowname=NULL)

# 要約統計量の変遷
g <- descriptive_status %>% mutate(range = max - min) %>%
  pivot_longer(-c(variable, title), names_to = "stat", values_to = "value") %>%
  filter(stat %in% c("range", "mean", "sd", "skewness", "kurtosis")) %>%
  mutate(stat = factor(stat, levels=c("range", "mean", "sd", "skewness", "kurtosis"))) %>%
  ggplot(aes(x = title, y = value, group = variable, color = variable)) + geom_line(size = 2) +
  facet_wrap(~stat, scales = "free_y", ncol = 1, strip.position = "left") + scale_color_colorblind()
g + theme_document_no_y
ggsave(filename = paste0("img/stat_document", ".pdf"), device = cairo_pdf)

g <- descriptive_status %>% mutate(range = max - min) %>%
  ggplot(aes(x = title, y = range, color = variable)) + geom_line(size = 2) + scale_color_colorblind()
g + theme_presen + theme(legend.key.width = unit(3, "line"))
ggsave(filename = paste0("img/stat_presen", ".pdf"), device = cairo_pdf, width = 10, height = 4)


# 1-100 だがレンジににばらつきがあるので正規化する
df_norm <- df_append %>% mutate(title = factor(title, levels=1:13)) %>% group_by(title) %>% group_map(
  ~mutate_if(.x, !names(.x) %in% c("attend_times", "at_first") & map_lgl(.x, is.numeric), function(x) scale_max_min(x) * 100),
  keep = T
) %>% bind_rows %>% rowwise %>% mutate(
  total = mean(c(武力, 知力, 魅力, 政治, 統率, 水指, 陸指), na.rm = T),
  total_sd = sd(c(武力, 知力, 魅力, 政治, 統率, 水指, 陸指), na.rm = T),
  total_range = max(c(武力, 知力, 魅力, 政治, 統率, 水指, 陸指), na.rm = T) -
    min(c(武力, 知力, 魅力, 政治, 統率, 水指, 陸指), na.rm = T)) %>% ungroup

df_norm %>% group_by(title) %>% my_skim
df_summary_norm <- df_norm %>% group_by(title) %>% select(title, 武力, 知力, 魅力, 政治) %>% my_skim() %>%
  as_tibble() %>% rename_all(~str_remove(.x, "^numeric.")) %>% rename(missings = n_missing) %>% filter(skim_type == "numeric") %>%
  select(-skim_type, -complete_rate) %>% rename(variable = skim_variable, min = p0, max = p100, skewness = skew, kurtosis = kurto)
df_summary_norm
Hmisc::latex(df_summary_norm %>% mutate_if(is.numeric, ~formatC(.x, digits = 2, format = "f")) %>%
               select(title, variable, min, p25, p50, p75, max, mean, sd, skewness, kurtosis),
             file="img/tab_descriptive.tex", rowname=NULL)

g <- df_summary_norm %>%
  pivot_longer(-c(variable, title), names_to = "stat", values_to = "value") %>%
  filter(stat %in% c("mean", "sd", "skewness", "kurtosis")) %>%
  mutate(stat = factor(stat, levels=c("mean", "sd", "skewness", "kurtosis"))) %>%
  ggplot(aes(x = title, y = value, group = variable, color = variable)) + geom_line(size = 2) +
  scale_color_colorblind() + 
  facet_wrap(~stat, scales = "free_y", ncol = 1, strip.position = "left")
g + theme_presen_no_y + theme(legend.key.width = unit(2.5, "line"))
ggsave(filename = "img/stat_norm_presen.pdf", device = cairo_pdf, width = 10, height = 8)
g + theme_document_no_y
ggsave(filename = "img/stat_norm_document.pdf", device = cairo_pdf)


for(i in 1:2){
  if(i == 1) x <- c("華雄", "関興")
  if(i == 2) x <- c("李通", "曹真")
  g <- df_norm %>% filter(name_id %in% x) %>%
    mutate(name_id = str_split(name_id, "", 2) %>% map_chr(function(x) paste(x, collapse = "\n"))) %>%
    select(title, name_id, 武力, 魅力, 知力, 政治) %>%
    pivot_longer(-c(title, name_id),
                 names_to = "status",
                 values_to = "value") %>%
    ggplot(aes(x = title, y = value, group = status, color = status, linetype = status)) +
    geom_line(size = 2) +
    facet_wrap(~name_id, ncol = 1, strip.position = "left") +
    scale_color_colorblind()
  print(g + theme_presen +
          theme(axis.text.y = element_blank(),
                legend.key.width = unit(3, "line"),
                strip.text.y = element_text(angle = 180, vjust = .5, size = 32)
          ) +
          labs(x = "Title"))
  ggsave(filename = paste0("img/personal", i, "_presen", ".pdf"),
         device = cairo_pdf, width = 10, height = 7)
}
df_norm %>% filter(name_id %in% c("華雄", "関興", "李通", "曹真")) %>%
  select(title, name_id, 武力, 魅力, 知力, 政治) %>%
  mutate(name_id = str_split(name_id, "") %>% map_chr(~paste(.x, collapse = "\n"))) %>%
  pivot_longer(-c(title, name_id), names_to = "status", values_to = "value") %>%
  ggplot(aes(x = title, y = value, group = status, color = status, linetype = status)) +
  geom_line(size = 1) +
  facet_wrap(~name_id, ncol = 1, strip.position = "left") +
  scale_color_colorblind() +
  theme_document_no_y + theme(strip.text.y.left = element_text(angle = 0))
ggsave(filename = "img/personal_document.pdf", device = cairo_pdf)



# シリーズごとの分布比較
for(s in c("武力", "知力", "魅力", "政治", "主要値平均")){
  g <- ggplot(df_norm %>% rename(主要値平均 = total), aes_string(x = "title", y = s, fill = "as.numeric(title)")) +
    geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
    scale_fill_continuous_tableau(guide = F) +
    labs(y = str_split(s, pattern = "") %>% unlist %>% paste(collapse = "\n"))
  print(g + theme_document + theme(axis.title.y = element_text(angle = 0, vjust = .5)) + labs(x = "タイトル"))
  ggsave(filename = paste0("img/", s, "_document.pdf"), device = cairo_pdf, width = 10, height = 4)
  print(g + labs(title = paste(s, "(min-max)")) + theme_presen)
  ggsave(filename = paste0("img/", s, "_presen.pdf"), device = cairo_pdf, width = 10, height = 4)
}

# まとめて1画像に
df_norm %>% rename(主要値平均 = total)  %>% select(title, 武力, 知力, 魅力, 政治, 主要値平均) %>%
  pivot_longer(cols=-title) %>%
  ggplot(aes(x = title, y = value, fill = as.numeric(title))) + geom_boxplot() +
  scale_fill_continuous_tableau(guide = F) + facet_wrap(~name, ncol = 1, strip.position = "left") +
  theme_document_no_y + labs(x = "タイトル")

df_norm %>% rename(主要値平均 = total)  %>% select(title, 武力, 知力, 魅力, 政治, 主要値平均) %>%
  pivot_longer(cols=-title) %>%
  ggplot(aes(x = title, y = value, fill = as.numeric(title))) + geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
  scale_fill_continuous_tableau(guide = F) + facet_wrap(~name, ncol = 1, strip.position = "left") +
  theme_document_no_y + labs(x = "タイトル")

g_concentrate <- ggplot(df_norm, aes(x = title, y = total, fill = as.integer(title))) +
  geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) + scale_fill_continuous_tableau(guide = F, "Classic Blue")
g_concentrate_sd <- ggplot(df_norm, aes(x = as.integer(title), y=total)) + stat_summary(fun = sd, geom = "line", size = 2) +
  stat_summary(fun = sd, geom = "point", size = 4) +
  scale_x_continuous(breaks = 1:13) + labs(title = "標準偏差")
g_concentrate_kurto <- ggplot(df_norm, aes(x = as.integer(title), y=total)) + stat_summary(fun = kurtosis, geom = "line", size = 2) +
  stat_summary(fun = kurtosis, geom = "point", size = 4) +
  scale_x_continuous(breaks = 1:13) + labs(title = "尖度")

g_concentrate + theme_presen
ggsave(filename = "img/主要値平均_presen1.pdf", device = cairo_pdf, width = 10, height = 5)

(g_concentrate_sd + theme_presen) / (g_polarize_kurto + theme_presen)
ggsave(filename = "img/主要値平均_presen2.pdf", device = cairo_pdf, width = 10, height = 8)

(g_concentrate + theme_document_no_y + theme(axis.title.x = element_blank())) /
  (g_concentrate_sd + theme_document_no_y + theme(axis.title.x = element_blank())) /
  (g_concentrate_kurto + theme_document_no_y + theme(axis.title.x = element_text(size = 15)) + labs(x = "タイトル"))
ggsave(filename = "img/主要値平均_document.pdf", device = cairo_pdf)

g <- ggplot(df_norm %>% select(title, total_range, total_sd) %>%
              pivot_longer(c(total_range, total_sd), names_to = "stat", values_to = "val") %>%
              mutate(stat = str_remove(stat, "^total_")),
       aes(x = title, y = val, fill = as.integer(title))) + geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
  scale_fill_continuous_tableau("Classic Blue", guide = F) +
  facet_wrap(~stat, scales = "free_y", ncol = 1, strip.position = "left")
g + theme_presen
ggsave(filename = "img/主要値moment_presen.pdf", device = cairo_pdf, width = 10, height = 7)
g + theme_document_no_y + labs(x =  "タイトル")
ggsave(filename = "img/主要値moment_document.pdf", device = cairo_pdf)

# 3軸での比較
g <- ggplot(df_norm, aes(x = 知力, y = 武力, color = attend_times)) + geom_point(shape = "x", size = 4) +
  scale_color_continuous_tableau("Classic Blue", breaks=seq(1, 13, 4)) + labs(color = "登場回数")
g + theme_presen + labs(y = "武\n力") +
  theme(axis.title.y = element_text(angle = 0, vjust = .5), legend.key.width = unit(4, "line"), legend.title = element_text(size = 20))
ggsave(filename = "img/scatter_times_presen.pdf", device = cairo_pdf, width = 10, height = 7)
g + theme_document
ggsave(filename = "img/scatter_times_document.pdf", device = cairo_pdf)

ggplot(df_norm, aes(x = 武力, y = 魅力, color = attend_times)) + geom_point(shape = "x", size = 2)
ggplot(df_norm, aes(x = 魅力, y = 政治, color = attend_times)) + geom_point(shape = "x", size = 2)
ggplot(df_norm, aes(x = 知力, y = 政治, color = attend_times)) + geom_point(shape = "x", size = 2)

# 塗りつぶされてるだけ?
g_scatter_first <- ggplot(df_norm, aes(x = 知力, y = 武力, color = at_first)) + geom_point(shape = "x", size = 4) +
  scale_color_continuous_tableau("Classic Blue", breaks=seq(1, 13, 4)) + labs(color = "初登場作品")
g_scatter_first + theme_presen +  labs(y = "武\n力") +
  theme(axis.title.y = element_text(angle = 0, vjust = .5), legend.key.width = unit(5, "line"), legend.title = element_text(size = 20))
g_scatter_first + theme_document

# ---- 勢力別に評価できるか? ----

# 主要な群雄の相性値を確認
df_norm %>% group_by(title) %>%
  filter(name_id %in% c("董卓", "曹操", "曹丕", "劉備", "劉禅", "孫堅", "孫権", "馬騰", "公孫瓚", "袁紹", "袁術", "劉表", "劉焉")) %>%
  group_map(~ggplot(.x, aes(x = 相性, y = 相性, label = name_id)) + geom_label())

# TODO: もっとかっこいいやり方
df_norm_faction <- df_norm %>% filter(!is.na(相性)) %>% group_by(title) %>%
  group_map(
    ~mutate(.x,
            蜀 = abs(相性 - filter(.x, name_id == "劉備")$相性),
            魏 = abs(相性 - filter(.x, name_id == "曹操")$相性),
            呉 = abs(相性 - filter(.x, name_id == "孫権")$相性)
            ) %>% pivot_longer(tidyselect::vars_select(names(.), 魏, 呉, 蜀), names_to = "faction", values_to = "dist") %>%
      group_by(name_id) %>% filter(rank(dist) == 1) %>% ungroup,
    keep = T
    ) %>% bind_rows %>% mutate(faction = factor(faction, levels = c("魏", "蜀", "呉")))

set.seed(42)
g_faction_str <- df_norm_faction %>% ggplot(aes(x = 相性, y = 武力, color = faction)) + geom_point() +
  geom_label(aes(label = name_id), data = group_by(df_norm_faction, title, faction) %>% sample_n(2)) + facet_wrap(~title)
g_faction_int <- df_norm_faction %>% ggplot(aes(x = 相性, y = 知力, color = faction)) + geom_point() +
  geom_label(aes(label = name_id), data = group_by(df_norm_faction, title, faction) %>% sample_n(2)) + facet_wrap(~title)
g_faction_total <- df_norm_faction %>% ggplot(aes(x = 相性, y = total, color = faction)) + geom_point() +
  geom_label(aes(label = name_id), data = group_by(df_norm_faction, title, faction) %>% sample_n(2)) + facet_wrap(~title) +
  labs(y = "主要ステータス平均")
g_faction_violin <- df_norm_faction %>% ggplot(aes(x = faction, y = total, fill = faction)) +
  geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) + facet_wrap(~title)
g_faction_violin + theme_document + labs(y = "主要ステータス平均")
ggsave(filename = "img/faction_violin_document.pdf", device = cairo_pdf)

g_faction_str + theme_document
ggsave(filename = "img/plot_by_faction_str_document.pdf", device = cairo_pdf)
g_faction_int + theme_document
ggsave(filename = "img/plot_by_faction_int_document.pdf", device = cairo_pdf)
g_faction_total + theme_document
ggsave(filename = "img/plot_by_faction_total_document.pdf", device = cairo_pdf)

g <- df_norm_faction %>% filter(title %in% c(2, 5, 8, 12)) %>% ggplot(aes(x = faction, y = total, fill = faction)) +
  geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
  facet_wrap(~title, strip.position = "left")
g + labs(y = "主要ステータス平均") +
  theme_presen_no_y + theme(
    strip.text.y = element_text(angle = -180),
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank())
ggsave(filename = "img/faction_violin_presen.pdf", device = cairo_pdf, width = 10, height = 7)

# 平均値との相関
df_norm %>% rowwise %>% mutate(
  x = 武力,
  y = mean(c(魅力, 政治, 知力), na.rm = T)
  ) %>% ungroup %>%
  ggplot(aes(x = x, y = y, color = attend_times)) + geom_point()

df_norm %>% rowwise %>% mutate(
  v = mean(c(武力, 魅力, 政治, 知力), na.rm = T)
) %>% ungroup %>%
  ggplot(aes(x = v, y = attend_times)) + geom_point()

# ---- 主成分分析でなんかできないか ----

# ワンライナーで書くと見づらすぎるので関数を定義して分割する
get_design_mat_input <- function(df){
  # デザイン行列作成に必要な列 + title, name_id を取り出す
  df %>% select_if(str_detect(names(.), "name_id") | map_lgl(., ~!is.character(.x))) %>%
    select(-order, -matches("生年|誕生|没年|登場|顔番号|相性")) %>% drop_na
}
convert_design_mat <- function(df, name = T, center = T, scale = T){
  # title, name_id 列を除いてデザイン行列に変換する (正規化処理オプションあり)
  model.matrix(
    ~.-1,
    select(df, -title, -name_id, -attend_times, -at_first) %>% mutate_if(is.numeric, ~scale(.x, center = center, scale = scale))
    ) %>% magrittr::set_rownames(df$name_id)
}

pca_conveted <- df_all %>% mutate(title = as.integer(title)) %>% group_by(title) %>%
  group_map(
    ~unnest(.x, cols = data) %>% get_design_mat_input %>% list(
      title = .$title[1],
      name = select(., name_id, attend_times),
      pca = prcomp(convert_design_mat(.), center = F, scale. = F)
      ),
    keep = T
    )

# 作品ごと
map(pca_conveted, ~(fviz_eig(.x$pca) / fviz_pca_var(.x$pca)) + plot_annotation(title = .x$title))
map(pca_conveted, ~fviz_pca_biplot(.x$pca) + labs(title=.x$title))

# 資料用に保存
fviz_pca_biplot(pca_conveted[[2]]$pca) + labs(
  title = "三國志II", caption ="https://github.com/Gedevan-Aleksizde/Japan.R2019\nデータ出典: http://hima.que.ne.jp/sangokushi/")
ggsave("img/pca_scatter2.pdf", device = cairo_pdf)
fviz_pca_biplot(pca_conveted[[9]]$pca) + labs(
  title = "三國志IX", caption ="https://github.com/Gedevan-Aleksizde/Japan.R2019\nデータ出典: http://lee.serio.jp/novel/sangoku/san9busho.html")
ggsave("img/pca_scatter9.pdf", device = cairo_pdf)

# 作品ごとの累積主成分寄与率を表示
g <- map_dfr(pca_conveted, ~get_eig(.x$pca) %>% as_tibble(rownames = "d") %>%
          select(d, variance.percent) %>%
          mutate(title = .x$title)) %>%
  mutate(variance.percent = variance.percent/100, d = factor(d, levels = rev(unique(d)))) %>%
  filter( d %in% paste0("Dim.", 1:2)) %>%
  ggplot(aes(x = title, y = variance.percent, group = d, fill = d)) + geom_bar(stat = "identity", position = "stack") +
  scale_fill_colorblind(guide = guide_legend(reverse = TRUE)) +
  labs(y = "accumurated importance") + scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = 1:13)
g + theme_presen_no_y
ggsave(filename = "img/pca_importance_presen.pdf", device = cairo_pdf, width = 10, height = 8)
g + theme_document
ggsave(filename = "img/pca_importance_document.pdf", device = cairo_pdf)

df_pca <- map_dfr(pca_conveted,
                  ~get_pca_ind(.x$pca)$coord %>%
                    as_tibble(rownames = "name_id") %>%
                    mutate(title = .x$title) %>%
                    inner_join(.x$name, by = "name_id")) %>%
  select(name_id, title, attend_times, Dim.1:Dim.3)

ggplot(df_pca, aes(x = Dim.1, y = Dim.2, color = attend_times)) + geom_point() + facet_wrap(~title)
