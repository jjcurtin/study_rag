#### Activity Generation ####
#Date: 11/16/2026
#Author: Jacki Zhang

options(conflicts.policy = "depends.ok")
library(tidyverse)
library(ragnar)
library(ellmer)

#recall store
store <- ragnar_store_connect(
  "manual.duckdb",
  read_only = FALSE
)

ragnar_store_inspect(store)

prompt_files <- list.files(
  "system_prompt",
  full.names = TRUE
)

system_prompt <- paste(
  sapply(prompt_files, function(f) {
    paste(readLines(f, warn = FALSE), collapse = "\n")
  }),
  collapse = "\n\n"
)

#one script that build the rag 

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

chat$chat("Create a one-page worksheet-style recovery activity for someone trying to manage intense emotions without using substances and they are often stressed out. The activity should include 4 to 6 brief fill-in prompts. Responses should be short enough to complete directly on a handout.") |> 
  as.character() |> 
  writeLines("output/emotion_regulation_1.txt")

prompt <- "Create a one-page worksheet-style recovery activity for someone trying to manage intense emotions without using substances and they are often angry. The activity should include 2 to 4 brief fill-in prompts. Responses should be short enough to complete directly on a handout."

response <- chat$chat(prompt)

paste0(
  "User Prompt:\n", prompt,
  "\n\n",
  "Output:\n", as.character(response)
) |> 
  writeLines("output/emotion_regulation_anger.txt")
