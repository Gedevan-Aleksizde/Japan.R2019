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

for(p in c("remotes", "cowplot", "colorspace", "Hmisc", "scales")){
  if(!p %in% installed.packages()) install.packages(p)
}
if(!"colorblindr" %in% installed.packages()) remotes::install_github("clauswilke/colorblindr")

conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")
conflict_prefer("select", "dplyr")

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

# 必要なフォルダ
# ./data

source("scraping.R")
sources <- map2_dfr(
  list(source1, source2, source3, source4, source5, source6, source7, source8, source9, source10, source11, source12, source13),
  1:13,
  function(x, t) tibble(x) %>% mutate(title=t, page=row_number())
) %>% mutate(html=map(x, as.character)) %>% select(-x)
write_rds(sources,  here("data", "sources.rds"))

sources <- read_rds(here("data", "sources.rds"))
source("tidying.R")
save(df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13, file=here("data", "df.RData"))
rm(sources, df1, df2, df3, df4, df5, df6, df7, df8, df9, df10, df11, df12, df13)

load(here("data", "df.RData"))
source("merge.R")
write_rds(df_all, path = here("data", "df_all.rds"))
