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
  model = "jackie-fyp",
  system_prompt = system_prompt,
  credentials = function() creds$key,
  api_args = list(
    reasoning = list(effort = "low"),
    text = list(verbosity = "low")
  )
)

chat_test <- ellmer::chat_azure_openai(
  endpoint = creds$url,
  model = "jackie-fyp",
  api_version = "2024-10-21",
  credentials = function() creds$key
)

chat_test$chat("Say hello.")

endpoint <- sub("/+$", "", creds$url)
api_key  <- creds$key[[1]]
req <- httr2::request(
  paste0(endpoint, "/openai/v1/responses")
) |>
  httr2::req_headers(
    `api-key` = api_key,
    `Content-Type` = "application/json"
  ) |>
  httr2::req_body_json(
    list(
      model = "jackid-fyp",
      input = "Say hello."
    )
  )

resp <- httr2::req_perform(req)
req_test <- httr2::request(
  paste0(endpoint, "/openai/v1/responses")
) |>
  httr2::req_headers(
    `api-key` = api_key,
    `Content-Type` = "application/json"
  ) |>
  httr2::req_body_json(
    list(
      model = "YOUR_EXACT_DEPLOYMENT_NAME",
      input = "Say hello."
    )
  ) |>
  httr2::req_error(
    is_error = function(resp) FALSE
  )

resp <- httr2::req_perform(req_test)

httr2::resp_status(resp)
httr2::resp_headers(resp)[["content-type"]]
httr2::resp_body_string(resp)

#testing retrival

ragnar_register_tool_retrieve(
  chat,
  store,
  top_k = 10
)

#test run? 
chat$chat("Create a short recovery activity for someone experiencing strong cravings to use substances.")
