# Used by "mix format"
locals_without_parens = [
  option: 2,
  option: 3,
  with_schema: 1,
  with_schema: 2
]

[
  export: [
    locals_without_parens: locals_without_parens
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  locals_without_parens: locals_without_parens
]
