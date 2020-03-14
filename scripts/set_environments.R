require(conflicted)
require(tidyverse)
require(ggthemes)
require(stringi)
require(here)
require(datapasta)
require(skimr)
require(patchwork)
require(rvest)
require(robotstxt)
require(SPARQL)
require(moments)
require(factoextra)
require(formattable)
require(patchwork)
require(cluster)
require(tictoc)
require(magick)
require(Metrics)
require(lubridate)

for(p in c("remotes", "cowplot", "colorspace", "Hmisc", "scales")){
  if(!p %in% installed.packages()) install.packages(p)
}
if(!"colorblindr" %in% installed.packages()) remotes::install_github("clauswilke/colorblindr")

conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_prefer("select", "dplyr")
conflict_prefer("here", "here")

# Mac, Windowsユーザは以下のフォントをインストールするか使用フォントを変更する
font_name <- "Noto Sans CJK JP"

theme_presen <- theme_base() +
  theme_classic(base_size = 30, base_family = font_name) +
  theme(legend.title = element_blank(),
        legend.position = "bottom",
        legend.key.width = unit(5, "line"),
        panel.grid.major.x = element_blank(),
        panel.grid.minor.y = element_blank(),
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        title = element_text(size = 20),
        strip.placement = "outside")
theme_presen_no_y <- theme_presen + theme(axis.title.y = element_blank())

theme_document <- theme_classic(base_family = font_name) + theme(
  axis.ticks = element_blank(),
  legend.position = "bottom",
  strip.placement = "outside",
  legend.key.width = unit(3, "line"),
  legend.title = element_blank()
)
theme_document_no_y <- theme_document + theme(axis.title.y = element_blank())

theme_set(theme_classic(base_family = font_name))

# フォルダ構成
# ./scripts/  all.R 他全ての .R ファイル
# ./data
# ./doc_src/img 画像保存用
dirname_scripts <- "scripts"
dirname_data <- "data"
dirname_img <- "doc_src/img"