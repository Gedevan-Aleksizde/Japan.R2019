if(!pacman::p_exists(keras)) pacman::p_install_gh("rstudio/keras")
pacman::p_load(tidyverse, ggthemes, cluster, factoextra, tictoc, magick, Metrics)

# 花園明朝A, B フォントが必要
# http://fonts.jp/hanazono/
# TODO: マルチバイト字が多いと構文チェックがバグる, 開くたびにテキストがぐちゃぐちゃになる

# TODO: グレースケールからさらに情報を落としてバイナリにしても問題なさそう
gen_string_image <- function(text, fpath = NULL, family = "HanaMinA", size = 32, n_char = NULL){
  if(is.null(n_char)) n_char <- str_length(text)
  if(is.null(fpath)) fpath <- tempfile()
  
  bmp(filename = fpath, width = size * str_length(text), height = size, units="px", pointsize = size)
  par(mar = rep(0, 4), family = family)
  plot(c(0, 1), c(0, 1), ann = F, bty = "n", type = "n", xaxt = "n", yaxt= "n")
  text(.5, .5, labels=text)
  dev.off()
  img <- image_read(fpath)
  return(image_scale(img, geometry_size_pixels(width = size * n_char, height = size, preserve_aspect = F))[[1]] %>% as.integer %>% .[, , 1])
}

mat2tidy <- function(m){
  as_tibble(m, .name_repair = "unique") %>% set_names(paste0(1:NCOL(.))) %>% mutate(y = rev(row_number())) %>%
    pivot_longer(cols = -y, names_to = "x", values_to = "col") %>%
    mutate(x = as.integer(x), col=as.numeric(col))
}

get_raster_feat <- function(df_names, ...){
  tmpfile <- tempfile()
  do.call(
    rbind,
    map(df_names$name_id, function(x){
      as.integer(gen_string_image(x, fpath = tmpfile, n_char=max(str_length(df_names$name_id)), ...))
      })
    ) %>%
    as_tibble(.name_repair = "unique") %>% select_if(function(x) var(x) > 0) %>% # 分散ゼロ要素が結構あるので除外
    mutate_all(.funs = scale) %>%
    mutate(name = df_names$name_id, num = row_number())
}

get_raster_feat2 <- function(df_names){
  tmpfile <- tempfile()
  max_len <- max(str_length(df_names$name_id))
  integrate1 <- function(x){
    x <- if_else(x < 127.5, 1:length(x), 0L)
    v <- max(x, na.rm=T) - min(x, na.rm=T)
    return(if_else(is.finite(v), v, 0L))
  }
  derivative <- function(x){
    length(rle(x<127.5)$values)
  }
  get_feats <- function(x){
    pixels <- gen_string_image(x, fpath = tmpfile, n_char = max_len, size=32) %>% as.data.frame
    return(
      unname(c(
        # rowwise
        # pmap_dbl(pixels, lift_vd(integrate1)),
        rowSums(pixels, na.rm=T),
        pmap_dbl(pixels, lift_vd(derivative)),
        # columnwise
        # as.numeric(summarise_all(pixels, integrate1)),
        colSums(pixels, na.rm=T),
        as.numeric(summarise_all(pixels, derivative))
      )
      ))
  }
  return(
    do.call(rbind, map(df_names$name_id, get_feats)) %>% as_tibble(.name_repair = "unique") %>%
      select_if(function(x) var(x) > 0) %>% # 分散ゼロ要素が結構あるので除外
      mutate_all(.funs = scale) %>%
      mutate(name = df_names$name_id, num = row_number())
    )
}

get_sim_rank <- function(df, df_names){
  tab_dist <- list()
  for(d in c("manhattan", "euclidean")){
    tab_dist[[d]] <- get_dist(dplyr::select(df, -name, -num), stand=T, method=d)
    tab_dist[[d]] <- tab_dist[[d]] %>% as.matrix %>% as_tibble %>% set_names(df_names$name_id) %>%
      mutate(name1=df_names$name_id) %>% pivot_longer(names_to = "name2", values_to = d, cols = -name1) %>%
      filter(name1 != name2) %>% rowwise %>%
      mutate(comb=paste(sort(c(name1, name2)), collapse="")) %>%
      distinct(comb, .keep_all=T) %>% dplyr::select(-comb)
  }
  df_sim_rank<- inner_join(tab_dist[[1]], tab_dist[[2]], by=c("name1", "name2")) %>%
    arrange(manhattan, euclidean) %>% ungroup %>%
    mutate_if(is.numeric, function(x) -as.numeric(scale(x))) %>%
    inner_join(df_names %>% mutate(num1 = row_number()) %>% rename(name1 = name_id), by = "name1") %>%
    inner_join(df_names %>% mutate(num2 = row_number()) %>% rename(name2 = name_id), by = "name2") %>%
    dplyr::select(num1, num2, name1, name2, everything())
  return(df_sim_rank)
}

nDCG <- function(relevance, best_relevance, p = length(relevance),
                 normalize = T, method = "Javelin", base = 2, return_scalar = T){
  if(method == "Javelin"){
    dcg_recursive <- function(x_lag, x, index){
      x_lag + x/log(x = index, base = base)
    }
  }
  else if(method == "Burges"){
    dcg_recursive <- function(x_lag, x, index){
      x_lag + (2^x) / log(x = index, base = base)
    }
  }
  else{
    stop('method is supported "Javelin" or "Burges" only.')
  }
  p <- min(p, length(relevance))
  dcg <- unlist(accumulate2(relevance[1:p], 2:p, function(lag, x, i){
    if(i < base){lag + x}
    else {dcg_recursive(lag, x, i)}
  }))
  if(normalize == T){
    dcg <- dcg / unlist(accumulate2(best_relevance[1:p], 2:p, function(lag, x, i){
      if(i < base){lag + x}
      else {dcg_recursive(lag, x, i)}
    }))
  }
  if(return_scalar == T){
    dcg <- tail(dcg, n = 1)
  }
  return(dcg)
}

theme_text_only <- theme_classic() + theme(
  axis.title=element_blank(), axis.ticks = element_blank(), axis.text = element_blank(),
  panel.grid = element_blank(), strip.text = element_blank())

df_all <- read_rds("data/df_all_merge.rds")

df_names <- dplyr::select(df_all, name_id) %>% mutate(name_id = str_replace(name_id, " (.+)$", "")) %>% distinct


# display sample images
bind_rows(
  gen_string_image("荀彧", n_char=3) %>% mat2tidy %>% mutate(name="荀彧"),
  gen_string_image("諸葛亮", n_char=3) %>% mat2tidy %>% mutate(name="諸葛亮"),
  gen_string_image("木鹿大王", n_char=3) %>% mat2tidy %>% mutate(name="木鹿大王")
) %>% mutate(name=factor(name, c("荀彧", "諸葛亮", "木鹿大王"))) %>% ggplot(aes(x=x, y=y, fill=col)) + geom_tile() +
  coord_fixed() + scale_fill_gradient(low="black", high="white") + facet_wrap(~name, ncol = 1) + theme_text_only


tic.clearlog()
tic("sim1")
df_raster <- get_raster_feat(df_names, size = 32)
df_sim_rank <- get_sim_rank(df_raster, df_names)
toc(log = T, quiet = T)
# save(df_names, df_raster, tab_rank_names, file="data/tmp1.RData")
# load("data/tmp1.RData")

df_sim_rank %>% arrange(desc(manhattan), desc(euclidean)) %>% head(20)
df_sim_rank %>% arrange(euclidean, manhattan) %>% head(20)

S <- df_raster %>% dplyr::select(-num, -name) %>% as.matrix %>% cor
det(S)

# 特徴量を減らす: 各行・列の非白ピクセル合計数
tic("sim2")
df_raster_feats <- get_raster_feat2(df_names)
df_sim_rank2 <- get_sim_rank(df_raster_feats, df_names)
toc(log = T, quiet = T)

S <- df_raster_feats %>% dplyr::select(-num, -name) %>% as.matrix %>% cor
det(S)
S %>% as_tibble %>% set_names(1:NCOL(S)) %>% mutate(row=row_number()) %>% pivot_longer(cols = -row, names_to = "col", values_to = "cor") %>%
  unique %>% mutate(col=as.integer(col)) %>%
  ggplot(aes(x=row, y=col, fill=cor)) + geom_tile() + scale_fill_gradient2() +
  labs(title="特徴量の相関行列") + theme_classic() + theme(axis.title=element_blank())


df_sim_rank2
Hmisc::latex(
  head(df_sim_rank2, 10) %>% dplyr::select(-num1, -num2) %>% mutate_if(is.numeric, function(x) round(x, 2)),
  file="doc/tab_sim.tex",
  rowname=NULL
)

df_sim_rank2 %>% arrange(desc(manhattan), desc(euclidean)) %>% head(20)
df_sim_rank2 %>% arrange(manhattan, euclidean) %>% head(20)
# save(df_names, df_raster, df_raster_feats, tab_rank_names, tab_rank_names2, file="data/tmp2.RData")
# load("data/tmp2.RData")

# 2つの方法による類似度の差異を確認
inner_join(df_sim_rank, df_sim_rank2, by = c("name1", "name2")) %>%
  summarise(
    RMSE = Metrics::rmse(manhattan.x, manhattan.y),
    MAE = Metrics::mae(manhattan.x, manhattan.y)
  )

tic.log()


# 1字同じなだけで類似度が高くなるので名前ごとの形状の類似度を見るだけでは限界 
# 1文字づつのクラスタリングで誤字候補洗い出し

df_chars <- tibble(
  name_id = df_names$name_id %>% paste0(collapse = "") %>% str_split_fixed(., pattern = "", n = str_length(.)) %>%
    as.character %>% unique
)
tic("sim3")
df_raster_feats_chr <- get_raster_feat(df_names=df_chars)
df_sim_rank3 <- get_sim_rank(df_raster_feats_chr, df_chars)
toc(T, T)
df_sim_rank3 # こっちのほうがうまくいかない