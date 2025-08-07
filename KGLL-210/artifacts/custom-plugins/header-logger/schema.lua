return {
  name = "header-logger",
  fields = {
    { config = {
        type = "record",
        fields = {
          { file_path = { type = "string", required = true } },
        },
      },
    },
  },
}

