#testing pipeline for a theoretical rag supported activity generation
#date: 10/22/2026

options(conflicts.policy = "depends.ok")
library(tidyverse)
library(ragnar)
library(ellmer)

doc <- read_as_markdown("manuals/Matrix Activities.pdf")

cat(as.character(doc))

chunky <- markdown_chunk(
  doc,
  target_size = 1600,
  target_overlap = .2
)

cat(chunky$text[1])
ragnar_chunks_view(chunky)

#note: remember to rotate sideways pages before extractions

# Create store
store <- ragnar_store_create(
  "manual.duckdb",
  embed = NULL,
  overwrite = TRUE
)

# Insert document chunks
ragnar_store_insert(store, chunky)

# Build retrieval index
ragnar_store_build_index(store)

system_prompt <- stringr::str_squish(
  "
  You are a clinical psychology expert specializing in substance use recovery.

  Before responding, retrieve relevant material from the knowledge store. Provide a citation for every source used. Do not answer unless you have retrieved and cited a source.
  
  You are writing a short therapeutic recovery activity for people with substance use disorder. Ground the activity in the retrieved material and follow the therapeutic approach, concepts, and techniques described in the knowledge store.

  Adapt the retrieved material into a clear, practical, and engaging activity rather than simply summarizing or reproducing the source material.
  
  The activity should: 
  - be approximately 1000-2000 characters long;
  - take 5 - 10 minutes to complete;
  - use supportive, non-judgemental language;
  - be focused on one specific recovery skill or goal;
  - be written for someone with a 8th grade reading level;
  - have varied sentence structure and minimize compound sentences;
  - appear to have been written by a human;
  - avoid using em dashes in your responses. Use commas or parentheses instead.

  "
)

creds <- readr::read_csv(
  "S:/other/credentials_jackie.csv",
  show_col_types = FALSE
)

chat <- ellmer::chat_azure_openai(
  endpoint = creds$url,
  model = "gpt-5.6-luna",
  system_prompt = system_prompt,
  credentials = function() creds$key,
  api_args = list(
    reasoning_effort = "none"
  )
)

#testing retrival

ragnar_register_tool_retrieve(
  chat,
  store,
  top_k = 10
)

#test run? 
chat$chat("Create a short recovery activity for someone experiencing strong cravings to use substances.")

chat$chat("Create a short recovery activity for someone with low motivation for recovery from substance use.")

ragnar_register_tool_retrieve(
  chat,
  store,
  top_k = 15
)

chat$chat("Create a short recovery activity for someone trying to manage intention emotions without using substances.")

chat$chat("Create a one-page worksheet-style recovery activity for someone trying to manage intense emotions without using substances. The activity should include 4 to 6 brief fill-in prompts. Responses should be short enough to complete directly on a handout.")
