#### RAG Generation ####
#Date: 11/16/2026
#Author: Jacki Zhang

library(tidyverse)
library(ragnar)

#note: remember to rotate sideways pages before extractions

# Create store
#store <- ragnar_store_create(
#  "manual.duckdb",
#  embed = NULL
#)

#Once store is created - recall store to add
store <- ragnar_store_connect(
  "manual.duckdb",
  read_only = FALSE
)

#Reading in Documents 

## Matrix Activities
matrix_act <- read_as_markdown("manuals/Matrix Activities.pdf")

#View full  
#cat(as.character(matrix_act))

#Chunk for storing
#should check ideal target size etc.
matrix_act_c <- markdown_chunk(
  matrix_act,
  target_size = 1600,
  target_overlap = .2
)

#View
cat(matrix_act_c$text[1])
ragnar_chunks_view(matrix_act_c)

## Project Match 02
match02 <- read_as_markdown("manuals/match02_redact.pdf")

#Chunk for storing
#should check ideal target size etc.
match02_c <- markdown_chunk(
  match02,
  target_size = 1600,
  target_overlap = .2
)

#View
cat(match02_c$text[1])
ragnar_chunks_view(match02_c)

# Insert document chunks
#ragnar_store_insert(store, matrix_act_c)
#ragnar_store_insert(store, match02_c)

# Build retrieval index 
#run every time documents are added
ragnar_store_build_index(store, type = "fts")

ragnar_store_inspect(store)
