require(tidyverse)
require(SPARQL)
require(rvest)
endpoint <-"http://ja.dbpedia.org/sparql"

# 記述が少なそうなマイナーな人物の場合
query <- "
PREFIX dbpedia: <http://ja.dbpedia.org/resource/> 
PREFIX dbp-owl: <http://dbpedia.org/ontology/>
PREFIX category-ja: <http://ja.dbpedia.org/resource/Category:>

SELECT DISTINCT *
WHERE {
  dbpedia:黄権 ?p ?o.
}"
res <- SPARQL(endpoint, query)
res$results %>% filter(str_detect(o, "Category"))
# wikiPageWikiLink に Category:三國志の登場人物 があるページを取ってくれば良さそう

query <- "
PREFIX dbpedia: <http://ja.dbpedia.org/resource/> 
PREFIX dbp-owl: <http://dbpedia.org/ontology/>
PREFIX category-ja: <http://ja.dbpedia.org/resource/Category:>

SELECT DISTINCT *
WHERE {
  dbpedia:鐘会 ?p ?o.
}"
res <- SPARQL(endpoint, query)
res$results %>% filter(str_detect(o, "Category"))


# 記述が多い主要人物の場合
query <- "
PREFIX dbpedia: <http://ja.dbpedia.org/resource/> 
PREFIX dbp-owl: <http://dbpedia.org/ontology/>
PREFIX category-ja: <http://ja.dbpedia.org/resource/Category:>

SELECT DISTINCT *
WHERE {
  dbpedia:劉備 ?p ?o.
}"
res <- SPARQL(endpoint, query)
res$results %>% filter(str_detect(o, "Category"))
# 「カテゴリ:三国志の登場人物」がついていない

# 記述が多い主要人物の場合
query <- "
PREFIX dbpedia: <http://ja.dbpedia.org/resource/> 
PREFIX dbp-owl: <http://dbpedia.org/ontology/>
PREFIX category-ja: <http://ja.dbpedia.org/resource/Category:>

SELECT DISTINCT *
WHERE {
  dbpedia:孫権 ?p ?o.
}"
res <- SPARQL(endpoint, query)
res$results %>% filter(str_detect(o, "Category"))
# 「カテゴリ:三国志の登場人物」がついていない


query_base <- "
PREFIX dbpedia: <http://ja.dbpedia.org/resource/>
PREFIX dbp-owl: <http://dbpedia.org/ontology/>
PREFIX rdf: <http://www.w3.org/2000/01/rdf-schema#>
PREFIX category-ja: <http://ja.dbpedia.org/resource/Category:>
"

source <- list()
source[["tk"]] <- SPARQL(endpoint,
       paste(
         query_base,
         "SELECT DISTINCT ?article, ?text WHERE {
         ?article dbp-owl:wikiPageWikiLink category-ja:三国志の登場人物 .
         ?article rdf:comment ?text .
         }",
         sep="\n"
         )
)$result %>% mutate(is_tk = T)
source[["engi"]] <- SPARQL(
  endpoint,
  paste(
    query_base,
    "SELECT DISTINCT ?article, ?text WHERE {
         ?article dbp-owl:wikiPageWikiLink category-ja:三国志演義の登場人物 .
         ?article rdf:comment ?text .
         }",
    sep="\n"
  )
)$result %>% mutate(is_engi = T)

source[["han"]] <- SPARQL(
  endpoint,
  paste(
    query_base,
    "SELECT DISTINCT ?article, ?text WHERE {
         ?article dbp-owl:wikiPageWikiLink category-ja:漢代の人物 .
         ?article rdf:comment ?text .
         }",
    sep="\n"
  )
)$result %>% mutate(is_han = T)

for (n in names(source)){
  print(n)
  source[[n]] <- source[[n]]  %>% mutate(
    article = str_replace(article, "<http://ja.dbpedia.org/resource/(.+)>", "\\1"), 
    text = str_extract(text, "^(.+?)[\\(|（]") %>% str_replace("[\\(|（]$", "") %>%
      str_remove('^"') %>% str_remove(" $")
  ) %>% as_tibble %>%
    filter(text != "歴史上の人物一覧") %>%
    mutate(text = if_else(str_sub(text, 1, 3) == "張 達", "張 達", text)) %>%
    mutate(text = if_else(str_sub(text, 1, 3) == "張尚", "張 尚", text)) %>%
    mutate(text = if_else(str_sub(text, 1, 3) == "孫 璋", "孫 璋", text)) %>%
    mutate(
      rownum = row_number(),
      name_id = str_remove(text, "\\s")
    )
}
df_wiki <- full_join(
  dplyr::select(source[["tk"]], article, name_id, is_tk),
  dplyr::select(source[["han"]], article, name_id, is_han),
  by = "article"
  ) %>%
  full_join(
    dplyr::select(source[["engi"]], article, name_id, is_engi),
    by = "article"
    ) %>% mutate(name_id = coalesce(name_id, name_id.x, name_id.y))
df_wiki <- df_wiki %>% dplyr::select(-name_id.x, -name_id.y)
df_wiki <- df_wiki %>% mutate_all(function(x) replace_na(x, F))
df_wiki %>% group_by(name_id) %>% summarise(n = n()) %>% arrange(desc(n))

df_wiki %>% filter(is_tk | is_engi) %>% filter(!is_han)

write_csv(df_wiki, path = "data/df_name_wiki.csv")

# こっからも取ってくる
# http://www.project-imagine.org/mujins/sanguo/
url_base <- "http://www.project-imagine.org/mujins/sanguo/persons50.html"
df_mujins <- read_html(url_base, encoding = "cp932") %>%
  html_nodes("a") %>% tibble(a = ., name_id = html_text(.), link = html_attr(., "href")) %>% dplyr::select(-a)
df_mujins %>% filter(str_detect(name_id, "[^\\p{Han}]")) %>% view
df_mujins <- df_names_hist %>% filter(!str_detect(name_id, "[^\\p{Han}]"))
write_csv(df_mujins, path = "data/df_name_mujins.csv")
