# 注: Mac は以下のプログラムで正しくpdfの保存ができない
if(!pacman::p_exists(patchwork)) pacman::p_install_gh("thomasp85/patchwork")
if(!pacman::p_exists(Hmisc)) install.packages(Hmisc)
pacman::p_load(tidyverse, ggthemes, stringr, here, skimr, patchwork, formattable, moments)

df_all <- read_rds(path = "data/df_all.rds")
# ----- 名寄せ完了 -----
df_all <- df_all %>% rename(name_old = name)

# データの傾向をグラフで確認
theme_presen <- theme_base() +
    theme_classic(base_size = 30, base_family = "Noto Sans CJK JP") +
    theme(legend.title = element_blank(), legend.position = "bottom",
          panel.grid.major.x = element_blank(),
          panel.grid.minor.y = element_blank(),
          title = element_text(size = 20),
          strip.placement = "outside")

theme_document <- theme_classic(base_family = "Noto Sans CJK JP") + theme(
  axis.ticks = element_blank(),
  legend.position = "bottom",
  strip.placement = "outside"
)


# 登場人物の採用・不採用の傾向
df_in_out <- df_all %>% dplyr::select(title, name_id) %>% mutate(exists = T, title = as.integer(title)) %>%
  right_join(x = ., y = expand_grid(title = unique(.$title), name_id = unique(.$name_id)), by = c("title", "name_id")) %>%
  mutate(exists = if_else(is.na(exists), F, T)) %>%
  arrange(name_id, title) %>% group_by(name_id) %>% mutate(join = !lag(exists) & exists, out = !exists & lag(exists)) %>% ungroup

# 検算
df_in_out  %>% group_by(title) %>% summarise(size = sum(exists), join = sum(join), out = sum(out)) %>% ungroup %>%
  mutate(net = join - out, valid = (size - (lag(size) + net)) == 0)


df_in_out %>% group_by(title) %>% skim()


g_in_out <- df_in_out %>% group_by(title) %>% summarise_if(is.logical, sum) %>% ungroup %>%
  mutate(keep = exists - join) %>% dplyr::select(-exists) %>%
  pivot_longer(-title, names_to = "var", values_to = "number") %>%
  mutate(var = factor(var, levels = c("out", "join", "keep"), labels = c("out", "in", "keep"))) %>%
  arrange(title, var) %>%
  ggplot(aes(x = title, y = number, group = var, fill = var,
             color = var, alpha = var == "out", linetype = (var == "out")
             )
         ) +
  geom_bar(stat = "identity", position = "stack", size = 1, width = .6) +
  scale_x_continuous(breaks = 2:13) + scale_fill_colorblind() +
  scale_alpha_manual(guide = F, values = c(T, F), breaks = c(100, 0)) +
  scale_linetype_manual(guide =F, values = c("solid", "dashed")) +
  scale_color_colorblind(guide = F)

g_in_out + theme_presen + theme(
  legend.title = element_blank(), axis.title.x = element_blank(), axis.title.y = element_blank()) +
  labs(title = "In/Out")
ggsave(filename = "doc/in_out_presen.pdf", device = cairo_pdf, width = 10, height = 6)
ggsave(filename = "doc/in_out_document.pdf", plot = g_in_out + theme_document + theme(legend.title = element_blank()), device = cairo_pdf)


# 人物ごと出入り回数の分布
df_in_out %>% mutate(keep = !join & !out) %>% dplyr::select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  arrange(desc(out))

df_in_out %>% mutate(keep = !join & !out) %>% dplyr::select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  arrange(desc(join))


df_in_out %>% mutate(keep = !join & !out) %>% dplyr::select(-exists) %>%
  group_by(name_id) %>% summarise_if(is.logical, sum, na.rm = T) %>% ungroup %>%
  pivot_longer(-name_id, names_to = "var", values_to = "number") %>%
  ggplot(aes(x = number, y = stat(density), group = var, fill = var)) +
  geom_histogram(position = "identity", bins = 10) +
  facet_wrap(~var, ncol = 1) + scale_fill_pander()


map(1:13, function(x) filter(df_all %>% mutate(title = as.integer(title)), title == x) %>%
      unnest(cols = data) %>% select_if(is.numeric)) %>% bind_rows %>%
  dplyr::select(title, 知力, 武力, 政治, 魅力) %>% group_by(title) %>% skim()

# 標準化して分布をよく調べる
df_norm <- list()
for(i in 1:13){
  df_norm[[i]] <- df_all %>% filter(title == as.character(i)) %>% unnest(cols = data) %>%
    mutate_if(is.numeric, function(x) as.numeric(scale(x))) %>%
    rename_if(names(.) == "カリスマ", function(x) "魅力") %>%
    select_if(names(.) %in% c("title", "name_id") | map_lgl(., is.numeric))
}

df_norm <- bind_rows(df_norm) %>% dplyr::select(title, name_id, 身体, 知力, 武力, 魅力, 運勢, 義理, 野望, 相性, 政治) %>%
  mutate(title = factor(title, levels=1:13))
# シリーズ皆勤賞人物に絞った場合も比較
attend_times <- df_all %>% group_by(name_id) %>% summarise(attend_times = n()) %>% ungroup 
df_norm <- inner_join(df_norm, attend_times, by = "name_id")



for(i in 1:2){
  if(i == 1) x <- c("華雄", "関興")
  if(i == 2) x <- c("李通", "曹真")
  g <- df_norm %>% filter(name_id %in% x) %>%
    mutate(name_id = str_split(name_id, "", 2) %>% map_chr(function(x) paste(x, collapse = "\n"))) %>%
    dplyr::select(title, name_id, 武力, 魅力, 知力, 政治) %>%
    pivot_longer(-c(title, name_id),
                 names_to = "status",
                 values_to = "value") %>%
    ggplot(aes(x = title, y = value, group = status, color = status, linetype = status)) +
    geom_line(size = 2) +
    facet_wrap(~name_id, ncol = 1, strip.position = "left") +
    scale_color_colorblind()
  print(g)
  ggsave(filename = paste0("doc/personal", i, "_presen", ".pdf"),
         plot = g + theme_presen +
           theme(axis.title.x = element_blank(),
                 axis.title.y = element_blank(), axis.text.y = element_blank(),
                 legend.position = "bottom", legend.title = element_blank(),
                 strip.text.y = element_text(angle = 180, vjust = .5, size = 32),
                 strip.placement = "outside"
           ) +
           labs(x = "Title"),
         device = cairo_pdf, width = 10, height = 7)
}
g <- df_norm %>% filter(name_id %in% c("華雄", "関興", "李通", "曹真")) %>%
  mutate(name_id = str_split(name_id, "", 2) %>% map_chr(function(x) paste(x, collapse = "\n"))) %>%
  dplyr::select(title, name_id, 武力, 魅力, 知力, 政治) %>%
  pivot_longer(-c(title, name_id), names_to = "status", values_to = "value") %>%
  ggplot(aes(x = title, y = value, group = status, color = status, linetype = status)) +
  geom_line(size = 1) +
  facet_wrap(~name_id, ncol = 1, strip.position = "left") +
  scale_color_colorblind() +
  theme_document + theme(
    legend.title = element_blank(),
    axis.title.y = element_blank(),
    strip.text.y = element_text(angle = 180, vjust = .5)
    )
ggsave(filename = "doc/personal_document.pdf", plot = g, device = cairo_pdf)

# シリーズ別ステータス値分布
my_skim <- skim_with(numeric = sfl(skew = skewness, kurto = kurtosis, hist = NULL), append = T)
descriptive_status <- df_norm %>% group_by(title) %>% dplyr::select(title, 武力, 知力, 魅力, 政治) %>% my_skim()
descriptive_status 
Hmisc::latex(descriptive_status %>% mutate_if(is.numeric, ~formatC(., digits = 2)) %>% dplyr::select(-skim_type),
             file="doc/tab_descriptive.tex", rowname=NULL)


for(s in c("武力", "知力", "魅力", "政治")){
  g <- ggplot(df_norm, aes_string(x = "title", y = s, fill = "as.numeric(title)")) +
    geom_violin(draw_quantiles = c(0.25, 0.5, 0.75)) +
    scale_fill_continuous_tableau(guide = F) +
    labs(y = str_split(s, pattern = "") %>% unlist %>% paste(collapse = "\n"))
  print(g)
  ggsave(plot = g + theme_document + theme(axis.title.y = element_text(angle = 0, vjust = .5)) + labs(x = "タイトル"),
         filename = paste0("doc/", s, "_document.pdf"), device = cairo_pdf)
  ggsave(plot = g + labs(title = s) +  theme_presen +
           theme(axis.title.x = element_blank(), axis.title.y = element_blank()),
         filename = paste0("doc/", s, "_presen.pdf"), device = cairo_pdf, width = 10, height = 6)
  g <- ggplot(df_norm, aes_string(x = "title", y = s, fill = "as.numeric(title)", color = "attend_times == 13")) +
    geom_violin() + geom_boxplot(fill = NA, size = 0.5) +
    scale_fill_continuous_tableau(guide = F) +
    scale_color_colorblind()
  print(g)
}

g <- ggplot(df_norm, aes(x = 知力, y = 武力, color = attend_times)) + geom_point(shape = "x", size = 2)
g + theme_presen + labs(y = "武\n力") + theme(axis.title.y = element_text(angle = 0, vjust = .5), legend.key.width = unit(7, "line"))
ggsave(plot = g + theme_presen + labs(y = "武\n力") + theme(axis.title.y = element_text(angle = 0, vjust = .5), legend.key.width = unit(7, "line")),
       filename = "doc/scatter_presen.pdf", device = cairo_pdf, width = 10, height = 7)
ggsave(plot = g + theme_document, filename = "doc/scatter_document.pdf", device = cairo_pdf)